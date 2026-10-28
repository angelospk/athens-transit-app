// Screen 2 · Στάση: arrivals at one stop, the user's lines first ("Οι γραμμές μου | Όλες"). It is the
// content of the map's sheet: a bus opens in the same sheet.

import 'dart:async';

import 'package:flutter/material.dart';

import '../core/eta.dart';
import '../core/models.dart';
import '../data/live.dart';
import '../data/store.dart';
import 'alert_sheet.dart';
import 'lines_picker.dart';
import 'theme.dart';
import 'map_sel.dart';
import 'widgets.dart';

class StopRef {
  const StopRef({required this.name, required this.lat, required this.lon, required this.lines});
  final String name;
  final double lat, lon;
  final List<String> lines; // every line that stops here
}

class StopPanel extends StatefulWidget {
  const StopPanel({super.key, required this.stop, required this.scroll});
  final StopRef stop;
  final ScrollController scroll;

  @override
  State<StopPanel> createState() => _StopPanelState();
}

class _StopPanelState extends State<StopPanel> {
  bool all = false;
  Map<String, LineLive> others = {};
  Timer? _timer;

  StopRef get s => widget.stop;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _timer ??= Timer.periodic(const Duration(seconds: 30), (_) => _loadOthers());
    if (others.isEmpty) _loadOthers();
  }

  Future<void> _loadOthers() async {
    final d = Deps.of(context);
    final rest = s.lines.where((l) => !d.store.myLines.contains(l));
    if (rest.isEmpty) return;
    final got = await d.live.nearbyLives(s.lat, s.lon, rest);
    if (mounted) setState(() => others = got);
  }

  @override
  void didUpdateWidget(StopPanel old) {
    super.didUpdateWidget(old);
    if (old.stop != widget.stop) {
      all = false;
      others = {};
      _loadOthers();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  List<Arrival> _arrivals(bool everything) {
    final d = Deps.of(context);
    final mine = s.lines.where(d.store.myLines.contains).toList();
    final out = d.live.arrivalsNear(s.name, s.lat, s.lon, only: mine);
    if (everything) {
      final now = d.live.nowS;
      for (final e in others.entries) {
        final st = d.live.statics[e.key];
        if (st == null) continue;
        for (final id in stopIdsNear(st, s.name, s.lat, s.lon)) {
          out.addAll(arrivalsAt(id, {e.key: st}, {e.key: e.value}, now));
        }
      }
      out.sort((a, b) => a.etaS.compareTo(b.etaS));
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final d = Deps.of(context);
    final t = context.tones;
    return ListenableBuilder(
      listenable: Listenable.merge([d.store, d.live]),
      builder: (context, _) {
        final mine = s.lines.where(d.store.myLines.contains).toList();
        final showAll = all || mine.isEmpty;
        final fav = d.store.favNear(s.name, s.lat, s.lon);
        final groups = groupArrivals(_arrivals(showAll));
        final estimate = d.live.isOffline;
        final quiet = s.lines.where((l) => !groups.any((g) => g.$1.line == l)).toList();
        // With "my lines", the other lines come below in short rows: "Περνούν επίσης".
        final also = showAll ? const <(Arrival, List<Arrival>)>[] : groupArrivals(_arrivals(true)).where((g) => !mine.contains(g.$1.line)).take(4).toList();
        return ListView(controller: widget.scroll, padding: const EdgeInsets.fromLTRB(16, 0, 16, 24), children: [
            const SheetHandle(),
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const BackSel(),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(titleCase(s.name), style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 2),
                  Text([if (fav?.place == Place.home) 'Σπίτι', if (fav?.place == Place.work) 'Δουλειά', '${s.lines.length} γραμμές'].join(' · '),
                      style: TextStyle(fontSize: 13, color: t.muted)),
                ]),
              ),
              IconButton.filledTonal(
                tooltip: fav == null ? 'Αποθήκευση στάσης' : 'Αποθηκευμένη στάση',
                isSelected: fav != null,
                icon: const Icon(Icons.star_outline),
                selectedIcon: const Icon(Icons.star),
                onPressed: () => fav == null ? _save(context) : d.store.removeFav(fav),
              ),
              const CloseSel(),
            ]),
            const SizedBox(height: 12),
            if (mine.isNotEmpty)
              SegmentedButton<bool>(
                segments: [
                  ButtonSegment(value: false, label: Text('Οι γραμμές μου · ${mine.length}')),
                  ButtonSegment(value: true, label: Text('Όλες · ${s.lines.length}')),
                ],
                selected: {all},
                onSelectionChanged: (v) => setState(() => all = v.first),
              ),
            const SizedBox(height: 4),
            if (estimate && groups.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(color: const Color(0xFFFFF0D1), borderRadius: BorderRadius.circular(14)),
                child: const Text('Οι χρόνοι είναι εκτίμηση από τα τελευταία δεδομένα και την ταχύτητα που έχει συνήθως η γραμμή. Διορθώνονται μόλις βρεθεί σήμα.',
                    style: TextStyle(fontSize: 13, height: 1.4, color: Color(0xFF3D2800))),
              ),
            if (groups.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Text('Κανένα λεωφορείο με GPS δεν έρχεται τώρα.', style: TextStyle(color: t.muted)),
              ),
            for (final (first, then) in groups)
              DecoratedBox(
                decoration: BoxDecoration(border: Border(bottom: BorderSide(color: t.rule))),
                child: ArrivalRow(
                  first: first,
                  then: then,
                  estimate: estimate,
                  onTap: () => mapSel.value = BusSel(first.line, first.vehicleId, stop: s),
                  trailing: IconButton.filled(
                    tooltip: 'Ειδοποίηση για το ${first.line}',
                    style: IconButton.styleFrom(backgroundColor: t.surface, foregroundColor: t.ink),
                    icon: const Icon(Icons.notifications_outlined),
                    onPressed: () => showAlertSheet(context, stop: s, arrival: first),
                  ),
                ),
              ),
            if (also.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.only(top: 16, bottom: 4),
                child: Text('Περνούν επίσης', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: t.muted)),
              ),
              for (final (a, _) in also)
                InkWell(
                  onTap: () => mapSel.value = BusSel(a.line, a.vehicleId, stop: s),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(children: [
                      LineBadge(a.line),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          ['→ ${titleCase(a.headsign)}', if (a.stopsLeft != null) a.stopsLeft == 1 ? 'επόμενη στάση' : '${a.stopsLeft} στάσεις'].join(' · '),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 14, color: t.muted),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text('${estimate ? '~' : ''}${mins(a.etaS)}', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                    ]),
                  ),
                ),
            ],
            if (quiet.isNotEmpty && showAll) ...[
              const SizedBox(height: 12),
              Text('Χωρίς λεωφορείο κοντά τώρα: ${quiet.join(', ')}', style: TextStyle(fontSize: 13, color: t.muted)),
            ],
            const SizedBox(height: 16),
            const LiveNote(),
          ]);
      },
    );
  }

  Future<void> _save(BuildContext context) async {
    final d = Deps.of(context);
    final picked = await pickLines(context, s.lines, s.lines.where(d.store.myLines.contains).toSet());
    if (picked == null) return;
    d.store.addFav(FavStop(name: s.name, lat: s.lat, lon: s.lon, lines: picked.toList()));
  }
}
