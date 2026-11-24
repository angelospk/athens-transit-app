// Screen 4 · Αγαπημένα: saved stops, ordered by the time of day (home in the morning, work in the
// afternoon), each with its lines' next arrivals and, in small type, the next of the other lines there;
// then the saved lines ("οι γραμμές μου"), each opening on the map.

import 'add_stop_screen.dart';
import 'dart:async';

import 'package:flutter/material.dart';

import '../core/eta.dart';
import '../core/models.dart';
import '../data/live.dart';

import '../core/athens_time.dart';
import '../core/last_bus.dart';
import '../core/nearby.dart';
import '../data/store.dart';
import '../l10n/l10n.dart';
import 'alert_sheet.dart' show dayClock, remindLast;
import 'map_sel.dart';
import 'menu.dart' show PlacesScreen;
import 'stop_screen.dart';
import 'theme.dart';
import 'widgets.dart';

class FavsScreen extends StatelessWidget {
  const FavsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final d = Deps.of(context);
    final t = context.tones;
    final s = context.l10n;
    return ListenableBuilder(
      listenable: Listenable.merge([d.store, d.live]),
      builder: (context, _) {
        final now = DateTime.now().toUtc();
        final favs = d.store.favsByTime(now);
        final morning = athensWall(now).hour < 15;
        final home = d.store.lastBusNudge && lastBusEvening(now)
            ? d.store.favs.where((f) => f.place == Place.home && f.lines.isNotEmpty).firstOrNull
            : null;
        return Scaffold(
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddStopScreen())),
            icon: const Icon(Icons.add),
            label: Text(s.favsAddStop),
          ),
          body: SafeArea(
            child: ListView(padding: const EdgeInsets.fromLTRB(12, 12, 12, 96), children: [
              // «Σπίτι», «Δουλειά» and other places live in «Μέρη».
              Card(
                elevation: 0,
                color: t.surface,
                margin: const EdgeInsets.fromLTRB(4, 4, 4, 8),
                child: ListTile(
                  leading: const Icon(Icons.place_outlined),
                  title: Text(d.store.home == null ? s.favsWhereHome : '${s.commonHome} · ${d.store.home!.label}'),
                  subtitle: Text(s.favsPlacesSub, style: TextStyle(fontSize: 12.5, color: t.muted)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => openPage(s.favsPlaces, const PlacesScreen()),
                ),
              ),
              // The time-of-day order only matters once a stop is marked «Σπίτι» or «Δουλειά».
              if (d.store.favs.any((f) => f.place != null))
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
                  child: Row(children: [
                    Dot(t.onTime),
                    const SizedBox(width: 6),
                    Text(morning ? s.favsMorning : s.favsAfternoon, style: TextStyle(fontSize: 13, color: t.muted)),
                  ]),
                ),
              if (home != null) _LastHome(key: ValueKey('last-${home.key}'), fav: home),
              if (favs.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(s.favsEmpty, style: TextStyle(color: t.muted)),
                ),
              _section(t, s.favsStops),
              for (final f in favs) _FavCard(key: ValueKey(f.key), fav: f),
              _section(t, s.favsLines),
              if (d.store.myLines.isEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
                  child: Text(s.favsLinesEmpty, style: TextStyle(color: t.muted)),
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

// Friday or Saturday evening (screen 24): the last bus of the day for the home stop, with an alert
// 30′ before it passes.
class _LastHome extends StatefulWidget {
  const _LastHome({super.key, required this.fav});
  final FavStop fav;

  @override
  State<_LastHome> createState() => _LastHomeState();
}

class _LastHomeState extends State<_LastHome> {
  late final Future<(LineStatic, ({String variant, int i, String t, int atStopS, String from}))?> _last = _load();
  bool _set = false;

  Future<(LineStatic, ({String variant, int i, String t, int atStopS, String from}))?> _load() async {
    final d = Deps.of(context);
    final f = widget.fav, line = f.lines.first;
    final st = d.live.statics[line] ?? await d.api.lineStatic(line);
    final sched = await d.api.lineSchedule(line);
    final h = sched == null ? null : homeLast(sched, st, stopIdsNear(st, f.name, f.lat, f.lon));
    return h == null ? null : (st, h);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tones;
    final s = context.l10n;
    final f = widget.fav;
    return FutureBuilder(
      future: _last,
      builder: (context, snap) {
        final got = snap.data;
        if (got == null) return const SizedBox.shrink();
        final (st, h) = got;
        final line = f.lines.first;
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.fromLTRB(14, 12, 8, 8),
          decoration: BoxDecoration(color: t.surface, borderRadius: BorderRadius.circular(18)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Icon(Icons.nightlight_outlined),
              const SizedBox(width: 10),
              Expanded(
                child: Text(s.favsLastHome(line), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ]),
            const SizedBox(height: 4),
            Text(
              s.favsLastHomeBody(gtfsClock(h.t), titleCase(h.from), dayClock(h.atStopS), titleCase(f.name)),
              style: TextStyle(fontSize: 14, color: t.muted),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                icon: Icon(_set ? Icons.check : Icons.notifications_active_outlined, size: 18),
                label: Text(_set ? s.favsWillNotify : s.alertNotifyMinutes(30)),
                onPressed: _set
                    ? null
                    : () async {
                        final messenger = ScaffoldMessenger.of(context);
                        final r = await remindLast(context, line: line, st: st, variantId: h.variant, i: h.i, stopName: f.name, beforeMin: 30);
                        if (mounted) setState(() => _set = r.ok);
                        messenger.showSnackBar(SnackBar(content: Text(r.msg)));
                      },
              ),
            ),
          ]),
        );
      },
    );
  }
}

// A saved line: buses on the road and how many are late; a tap opens it on the map.
class _LineRow extends StatelessWidget {
  const _LineRow({required this.line});
  final String line;

  @override
  Widget build(BuildContext context) {
    final d = Deps.of(context);
    final t = context.tones;
    final s = context.l10n;
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
                  vs.isEmpty ? s.favsNoGpsBus : '${s.favsOnRoad(vs.length)} · ${late == 0 ? s.favsAllOnTime : s.favsLate(late)}',
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

  Toward? _toward; // which way the buses leave this stop

  // The other lines of the stop, from the citywide tiles (they are not watched).
  Future<void> _load() async {
    final d = Deps.of(context);
    try {
      final ix = await d.api.trips();
      if (_toward == null && mounted) setState(() => _toward = towardAt(ix, fav.name, fav.lat, fav.lon));
      if (_all.isEmpty) _all = linesAt(ix, fav.name, fav.lat, fav.lon);
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
    final s = context.l10n;
    final groups = groupArrivals(d.live.arrivalsNear(fav.name, fav.lat, fav.lon, only: fav.lines));
    // With no saved line coming, two of the others; with some, one.
    final also = groupArrivals(_otherArrivals()).take(groups.isEmpty ? 2 : 1).toList();
    final quiet = fav.lines.where((l) => !groups.any((g) => g.$1.line == l));
    final place = switch (fav.place) { Place.home => s.commonHome, Place.work => s.commonWork, null => null };
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(16, 14, 8, 6),
      decoration: Ds.card(t),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        InkWell(
          onTap: _open,
          child: Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(titleCase(fav.name), style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w600)),
                if (place != null) Text(place, style: TextStyle(fontSize: 13, color: t.muted)),
                if (_toward case final w?) Padding(padding: const EdgeInsets.only(top: 2), child: TowardRow(w)),
              ]),
            ),
            PopupMenuButton<String>(
              tooltip: s.favsOptions,
              onSelected: (v) => switch (v) {
                'home' => d.store.updateFav(fav.copyWith(place: Place.home)),
                'work' => d.store.updateFav(fav.copyWith(place: Place.work)),
                'none' => d.store.updateFav(fav.copyWith(clearPlace: true)),
                _ => d.store.removeFav(fav),
              },
              itemBuilder: (_) => [
                PopupMenuItem(value: 'home', child: Text(s.favsIsHome)),
                PopupMenuItem(value: 'work', child: Text(s.favsIsWork)),
                PopupMenuItem(value: 'none', child: Text(s.favsNeither)),
                PopupMenuItem(value: 'remove', child: Text(s.favsRemove)),
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
            child: Text(s.favsQuiet(quiet.join(', ')), style: TextStyle(fontSize: 13, color: t.muted)),
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
                Expanded(child: Text('→ ${towards(a)}', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13, color: t.muted))),
                EtaChip('${d.live.isOffline ? '~' : ''}${mins(a.etaS)}',
                    live: !d.live.isOffline, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: t.muted, fontFeatures: Ds.tabular)),
              ]),
            ),
          ),
        if (_all.length > fav.lines.length)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(onPressed: _open, child: Text(s.favsAllLines(_all.length))),
          ),
      ]),
    );
  }
}
