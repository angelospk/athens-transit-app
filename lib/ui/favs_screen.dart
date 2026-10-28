// Screen 4 · Αγαπημένα: saved stops, ordered by the time of day (home in the morning, work in the
// afternoon), each with its lines' next arrivals and, in small type, the next of the other lines there;
// then the saved lines ("οι γραμμές μου"), each opening on the map.

import 'dart:async';

import 'package:flutter/material.dart';

import '../core/eta.dart';
import '../core/models.dart';
import '../data/live.dart';

import '../core/athens_time.dart';
import '../core/nearby.dart';
import '../data/store.dart';
import 'map_sel.dart';
import 'onboard_screen.dart';
import 'stop_screen.dart';
import 'theme.dart';
import 'widgets.dart';

class FavsScreen extends StatelessWidget {
  const FavsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final d = Deps.of(context);
    final t = context.tones;
    return ListenableBuilder(
      listenable: Listenable.merge([d.store, d.live]),
      builder: (context, _) {
        final now = DateTime.now().toUtc();
        final favs = d.store.favsByTime(now);
        final morning = athensWall(now).hour < 15;
        return Scaffold(
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const OnboardScreen(adding: true))),
            icon: const Icon(Icons.add),
            label: const Text('Στάση'),
          ),
          body: SafeArea(
            child: ListView(padding: const EdgeInsets.fromLTRB(12, 12, 12, 96), children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
                child: Text('Αγαπημένα', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontSize: 28)),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
                child: Row(children: [
                  Dot(t.onTime),
                  const SizedBox(width: 6),
                  Text(morning ? 'Πρωί: πρώτα η στάση του σπιτιού' : 'Απόγευμα: πρώτα η στάση της δουλειάς', style: TextStyle(fontSize: 13, color: t.muted)),
                ]),
              ),
              if (favs.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text('Καμία αποθηκευμένη στάση ακόμη. Πάτα «+ Στάση».', style: TextStyle(color: t.muted)),
                ),
              _section(t, 'Στάσεις'),
              for (final f in favs) _FavCard(key: ValueKey(f.key), fav: f),
              _section(t, 'Γραμμές'),
              if (d.store.myLines.isEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
                  child: Text('Καμία γραμμή ακόμη. Πάτα το αστέρι σε μια γραμμή για να τη βλέπεις εδώ.', style: TextStyle(color: t.muted)),
                ),
              for (final l in d.store.myLines) _LineRow(line: l),
            ]),
          ),
        );
      },
    );
  }

  Widget _section(Tones t, String s) => Padding(
        padding: const EdgeInsets.fromLTRB(8, 12, 8, 8),
        child: Text(s, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: t.muted, letterSpacing: .3)),
      );
}

// A saved line: buses on the road and how many are late; a tap opens it on the map.
class _LineRow extends StatelessWidget {
  const _LineRow({required this.line});
  final String line;

  @override
  Widget build(BuildContext context) {
    final d = Deps.of(context);
    final t = context.tones;
    final vs = d.live.lives[line]?.vehicles ?? const <Vehicle>[];
    final late = vs.where((v) => (v.delayS ?? 0) > 300).length;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: t.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => showOnMap(LineSel(line)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
          child: Row(children: [
            LineBadge(line, big: true),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                FutureBuilder(
                  future: d.api.lines(),
                  builder: (context, snap) => Text(titleCase(snap.data?.where((l) => l.id == line).firstOrNull?.name ?? ''),
                      maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                ),
                Text(
                  vs.isEmpty ? 'κανένα λεωφορείο με GPS τώρα' : '${vs.length} στον δρόμο · ${late == 0 ? 'όλα στην ώρα τους' : '$late ${late == 1 ? 'αργεί' : 'αργούν'}'}',
                  style: TextStyle(fontSize: 13, color: late == 0 ? t.muted : t.late),
                ),
              ]),
            ),
            Icon(Icons.chevron_right, color: t.muted),
          ]),
        ),
      ),
    );
  }
}

class _FavCard extends StatefulWidget {
  const _FavCard({super.key, required this.fav});
  final FavStop fav;

  @override
  State<_FavCard> createState() => _FavCardState();
}

class _FavCardState extends State<_FavCard> {
  List<String> _all = []; // every line at the stop
  Map<String, LineLive> _others = {};
  Timer? _timer;

  FavStop get fav => widget.fav;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _timer ??= Timer.periodic(const Duration(seconds: 30), (_) => _load());
    if (_all.isEmpty) _load();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // The other lines of the stop, from the citywide tiles (they are not watched).
  Future<void> _load() async {
    final d = Deps.of(context);
    try {
      if (_all.isEmpty) _all = linesAt(await d.api.trips(), fav.name, fav.lat, fav.lon);
      final rest = _all.where((l) => !fav.lines.contains(l));
      if (rest.isEmpty) return;
      final got = await d.live.nearbyLives(fav.lat, fav.lon, rest);
      if (mounted) setState(() => _others = got);
    } catch (_) {/* offline: only the saved lines */}
  }

  List<Arrival> _otherArrivals() {
    final d = Deps.of(context);
    final out = <Arrival>[];
    for (final e in _others.entries) {
      final st = d.live.statics[e.key];
      if (st == null) continue;
      for (final id in stopIdsNear(st, fav.name, fav.lat, fav.lon)) {
        out.addAll(arrivalsAt(id, {e.key: st}, {e.key: e.value}, d.live.nowS));
      }
    }
    return out..sort((a, b) => a.etaS.compareTo(b.etaS));
  }

  Future<void> _open() async {
    final d = Deps.of(context);
    final all = _all.isNotEmpty ? _all : linesAt(await d.api.trips(), fav.name, fav.lat, fav.lon);
    showOnMap(StopSel(StopRef(name: fav.name, lat: fav.lat, lon: fav.lon, lines: all.isEmpty ? fav.lines : all)));
  }

  @override
  Widget build(BuildContext context) {
    final d = Deps.of(context);
    final t = context.tones;
    final groups = groupArrivals(d.live.arrivalsNear(fav.name, fav.lat, fav.lon, only: fav.lines));
    // With no saved line coming, two of the others; with some, one.
    final also = groupArrivals(_otherArrivals()).take(groups.isEmpty ? 2 : 1).toList();
    final quiet = fav.lines.where((l) => !groups.any((g) => g.$1.line == l));
    final place = switch (fav.place) { Place.home => 'Σπίτι', Place.work => 'Δουλειά', null => null };
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(16, 14, 8, 6),
      decoration: BoxDecoration(color: t.surface, borderRadius: BorderRadius.circular(24)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        InkWell(
          onTap: _open,
          child: Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(titleCase(fav.name), style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w600)),
                if (place != null) Text(place, style: TextStyle(fontSize: 13, color: t.muted)),
              ]),
            ),
            PopupMenuButton<String>(
              tooltip: 'Επιλογές',
              onSelected: (v) => switch (v) {
                'home' => d.store.updateFav(fav.copyWith(place: Place.home)),
                'work' => d.store.updateFav(fav.copyWith(place: Place.work)),
                'none' => d.store.updateFav(fav.copyWith(clearPlace: true)),
                _ => d.store.removeFav(fav),
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'home', child: Text('Είναι το σπίτι')),
                PopupMenuItem(value: 'work', child: Text('Είναι η δουλειά')),
                PopupMenuItem(value: 'none', child: Text('Ούτε σπίτι ούτε δουλειά')),
                PopupMenuItem(value: 'remove', child: Text('Αφαίρεση')),
              ],
            ),
          ]),
        ),
        for (final (first, then) in groups)
          DecoratedBox(
            decoration: BoxDecoration(border: Border(top: BorderSide(color: t.rule))),
            child: Padding(padding: const EdgeInsets.only(right: 8), child: ArrivalRow(first: first, then: then, big: true, estimate: d.live.isOffline)),
          ),
        if (quiet.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(0, 8, 8, 4),
            child: Text('Χωρίς λεωφορείο με GPS τώρα: ${quiet.join(', ')}', style: TextStyle(fontSize: 13, color: t.muted)),
          ),
        // The other lines, small: the next one or two, and a way to all of them on the map.
        for (final (a, _) in also)
          InkWell(
            onTap: _open,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(0, 6, 8, 2),
              child: Row(children: [
                Text(a.line, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: t.muted)),
                const SizedBox(width: 8),
                Expanded(child: Text('→ ${titleCase(a.headsign)}', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13, color: t.muted))),
                Text('${d.live.isOffline ? '~' : ''}${mins(a.etaS)}', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: t.muted)),
              ]),
            ),
          ),
        if (_all.length > fav.lines.length)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(onPressed: _open, child: Text('Όλες οι γραμμές εδώ (${_all.length}) ›')),
          ),
      ]),
    );
  }
}
