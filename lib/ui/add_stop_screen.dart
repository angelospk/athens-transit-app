// «+ Στάση»: a stop near the user (or found by name) and its lines, saved in «Δικά μου». The app has
// no first-run screen: the map opens first and asks for location with a reason.

import 'package:flutter/material.dart';

import '../core/nearby.dart';
import '../data/locate.dart';
import '../data/store.dart';
import 'theme.dart';
import 'widgets.dart';

class AddStopScreen extends StatefulWidget {
  const AddStopScreen({super.key});

  @override
  State<AddStopScreen> createState() => _AddStopScreenState();
}

class _AddStopScreenState extends State<AddStopScreen> {
  List<NearbyStop>? stops;
  NearbyStop? picked;
  final sel = <String>{};
  bool noLocation = false;
  String query = '';
  final _linesKey = GlobalKey(); // the lines question, scrolled into view once a stop is picked

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (stops == null) _load();
  }

  Future<void> _load() async {
    final d = Deps.of(context);
    final ix = await d.api.trips();
    final p = await knownPosition();
    if (!mounted) return;
    setState(() {
      noLocation = p == null;
      stops = nearbyStops(ix, p ?? athensCentre, radiusM: 800, max: 6);
    });
  }

  Future<void> _search(String q) async {
    final d = Deps.of(context);
    query = q;
    final ix = await d.api.trips();
    if (q.trim().length < 2) return _load();
    final f = fold(q);
    final hits = <NearbyStop>[];
    final seen = <String>{};
    for (var i = 0; i < ix.s.length && hits.length < 8; i++) {
      final s = ix.s[i];
      if (!fold(s.$1).contains(f) || !seen.add(s.$1)) continue;
      hits.addAll(nearbyStops(ix, (s.$2, s.$3), radiusM: 50, max: 1));
    }
    if (mounted && query == q) setState(() => stops = hits);
  }

  void _done() {
    final d = Deps.of(context);
    final p = picked;
    if (p != null) {
      d.store.addFav(FavStop(
        name: p.name,
        lat: p.lat,
        lon: p.lon,
        lines: sel.toList(),
      ));
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tones;
    final store = Deps.of(context).store;
    final room = maxLines - store.myLines.length;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: t.ground,
        surfaceTintColor: Colors.transparent,
      ),
      body: SafeArea(top: false, child: ListView(padding: const EdgeInsets.fromLTRB(20, 0, 20, 24), children: [
        Text('Ποια στάση θέλεις να κρατήσεις;', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 6),
        Text('Θα τη βρίσκεις στα αγαπημένα, με τις γραμμές που διαλέγεις.', style: TextStyle(color: t.muted)),
        const SizedBox(height: 12),
        TextField(
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.search),
            hintText: noLocation ? 'Γράψε το όνομα της στάσης' : 'Ή γράψε το όνομα της στάσης',
            filled: true,
            fillColor: t.surface,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(28), borderSide: BorderSide.none),
          ),
          style: const TextStyle(fontSize: 16),
          onChanged: _search,
        ),
        const SizedBox(height: 8),
        if (stops == null) const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator())),
        if (stops != null && stops!.isEmpty)
          Padding(padding: const EdgeInsets.all(16), child: Text('Δεν βρέθηκε στάση. Γράψε το όνομά της.', style: TextStyle(color: t.muted))),
        for (final (i, s) in (stops ?? const <NearbyStop>[]).indexed)
          Card(
            elevation: 0,
            color: picked == s ? t.indicator : t.surface,
            margin: const EdgeInsets.symmetric(vertical: 4),
            child: ListTile(
              leading: CircleAvatar(backgroundColor: t.ground, child: Text('${i + 1}')),
              title: Text('${titleCase(s.name)}${query.isEmpty ? ' · ${s.distM.round()} μ.' : ''}', style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text(s.lines.join(', '), maxLines: 1, overflow: TextOverflow.ellipsis),
              onTap: () {
                FocusScope.of(context).unfocus(); // the keyboard would cover the lines
                setState(() {
                  picked = s;
                  sel
                    ..clear()
                    ..addAll(s.lines.where(store.myLines.contains));
                });
                // The second question is below the list: bring it into view, so it is not missed.
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  final c = _linesKey.currentContext;
                  if (c != null && c.mounted) Scrollable.ensureVisible(c, duration: const Duration(milliseconds: 300), alignment: .1);
                });
              },
            ),
          ),
        if (picked != null) ...[
          const SizedBox(height: 16),
          Text('Ποιες γραμμές σε νοιάζουν εδώ;', key: _linesKey, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final l in picked!.lines)
              FilterChip(
                label: Text(l, style: const TextStyle(fontWeight: FontWeight.w700)),
                selected: sel.contains(l),
                onSelected: (on) => setState(() => on
                    ? (sel.where((x) => !store.myLines.contains(x)).length < room || store.myLines.contains(l) ? sel.add(l) : null)
                    : sel.remove(l)),
              ),
          ]),
          const SizedBox(height: 6),
          Text('Ως $maxLines γραμμές συνολικά.', style: TextStyle(fontSize: 12, color: t.muted)),
        ],
        const SizedBox(height: 20),
        // A disabled button says what is still missing.
        SizedBox(
          height: 52,
          child: FilledButton(
            onPressed: picked == null || sel.isEmpty ? null : _done,
            child: Text(picked == null ? 'Διάλεξε στάση' : sel.isEmpty ? 'Διάλεξε τουλάχιστον μία γραμμή' : 'Αποθήκευση'),
          ),
        ),
      ])),
    );
  }
}
