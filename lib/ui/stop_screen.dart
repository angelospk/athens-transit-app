// Screen 2 · Στάση: arrivals at one stop, the user's lines first ("Οι γραμμές μου | Όλες"). It is the
// content of the map's sheet: a bus opens in the same sheet.

import 'dart:async';

import 'package:flutter/material.dart';

import '../core/athens_time.dart';
import '../core/eta.dart';
import '../core/models.dart';
import '../core/rules.dart';
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
  Map<String, Map<String, dynamic>> _schedules = {}; // line -> today's timetable, when the backend has it
  Timer? _timer;

  StopRef get s => widget.stop;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // The timetable too, now and then: a run that did not start is known only some minutes after it.
    _timer ??= Timer.periodic(const Duration(seconds: 30), (t) {
      _loadOthers();
      if (t.tick % 10 == 0) _loadSchedules();
    });
    if (others.isEmpty) _loadOthers();
    if (_schedules.isEmpty) _loadSchedules();
  }

  Future<void> _loadSchedules() async {
    final api = Deps.of(context).api;
    final stop = s;
    final lines = stop.lines.toList();
    final all = <Map<String, dynamic>?>[];
    for (var k = 0; k < lines.length; k += 6) {
      // A few at a time: the server queues at most 16 OASA calls, and a refused one falls back to the old GTFS.
      all.addAll(await Future.wait(lines.skip(k).take(6).map(api.cachedSchedule)));
      if (!mounted || stop != s) return;
    }
    final got = <String, Map<String, dynamic>>{
      for (var k = 0; k < lines.length; k++)
        if (all[k] case final j? when j['expired'] != true) lines[k]: j, // an expired timetable is not today's
    };
    if (!mounted || stop != s) return;
    await Deps.of(context).live.loadStatics(got.keys); // no bus near: the route still places the stop
    if (mounted && stop == s) setState(() => _schedules = got);
  }

  // Runs not started yet, from today's timetable: one direction per headsign, after the last live bus
  // of that direction. (line, headsign, eta s), soonest first. Into [missed]: the runs that did not
  // start and would be here about now (line, headsign, departure, the line's end).
  List<(String, String, int)> _planned(List<String> lines, List<Arrival> live, [List<_Missed>? missed]) {
    final d = Deps.of(context);
    final w = athensWall(DateTime.now().toUtc());
    final nowWall = w.hour * 3600 + w.minute * 60 + w.second;
    final out = <(String, String, int)>[];
    for (final l in lines) {
      final j = _schedules[l], st = d.live.statics[l];
      if (j == null || st == null) continue;
      final ids = stopIdsNear(st, s.name, s.lat, s.lon).toSet();
      final best = <String, (String, int)>{}; // headsign -> (variant, stop index), the longest variant
      for (final e in st.variants.entries) {
        final i = e.value.stops.indexWhere(ids.contains);
        if (i < 0 || i == e.value.stops.length - 1) continue; // the terminus: nobody boards there
        final b = best[e.value.headsign];
        if (b == null || st.variants[b.$1]!.stops.length < e.value.stops.length) best[e.value.headsign] = (e.key, i);
      }
      final used = <Map<String, dynamic>>{}; // two variants on one timetable direction (a Saturday detour) are one run
      final byLength = best.entries.toList()..sort((a, b) => st.variants[b.value.$1]!.stops.length.compareTo(st.variants[a.value.$1]!.stops.length));
      for (final MapEntry(key: h, value: (vid, i)) in byLength) {
        final dir = directionFor(j, st.variants[vid]!);
        if (dir == null || !used.add(dir)) continue;
        final deps = departuresFor(j, st.variants[vid]!)!;
        if (missed != null) {
          final end = st.stops[st.variants[vid]!.stops.last];
          for (final m in missedRuns(j, st, vid, i, nowWall)) {
            if (end != null) missed.add((line: l, headsign: h, t: m.t, end: (label: end.name, pts: [(end.lat, end.lon)])));
          }
        }
        final after = live.where((a) => a.line == l && a.headsign == h).fold<int?>(null, (m, a) => m == null || a.etaS > m ? a.etaS : m);
        for (final eta in plannedEtas(deps, st, vid, i, nowWall, afterS: after).take(2)) {
          out.add((l, h, eta));
        }
      }
    }
    return out..sort((a, b) => a.$3.compareTo(b.$3));
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
      _schedules = {};
      _loadOthers();
      _loadSchedules();
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

  // The bell of a line: filled while an alert for it at this stop is set.
  Widget _bell(BuildContext context, StopRef s, Arrival a) {
    final t = context.tones;
    final d = Deps.of(context);
    final set = hasAlert(d.store.rules, a.line, s.name, d.live.nowS);
    return IconButton.filled(
      tooltip: set ? 'Ειδοποίηση για το ${a.line}: ενεργή' : 'Ειδοποίησέ με για το ${a.line}',
      style: IconButton.styleFrom(backgroundColor: set ? t.ink : t.surface, foregroundColor: set ? t.ground : t.ink),
      icon: Icon(set ? Icons.notifications_active : Icons.notifications_outlined),
      onPressed: () => showAlertSheet(context, stop: s, arrival: a),
    );
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
        final missed = <_Missed>[];
        final planned = _planned(showAll ? s.lines : mine, _arrivals(true), missed).take(6).toList();
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
                  trailing: _bell(context, s, first),
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
            if (missed.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.only(top: 16, bottom: 4),
                child: Text('Δεν ξεκίνησαν · δεν είδα λεωφορείο να φεύγει από την αφετηρία', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: t.late)),
              ),
              for (final m in missed)
                Row(children: [
                  LineBadge(m.line),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text('→ ${titleCase(m.headsign)} · των ${m.t}', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 14, color: t.muted)),
                  ),
                  TextButton(
                    onPressed: () => showPlanner(from: (label: s.name, pts: [(s.lat, s.lon)]), to: m.end),
                    child: const Text('Άλλη επιλογή'),
                  ),
                ]),
            ],
            if (planned.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.only(top: 16, bottom: 4),
                child: Text('Δεν ξεκίνησαν ακόμη · από το πρόγραμμα', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: t.muted)),
              ),
              for (final (line, h, eta) in planned)
                InkWell(
                  onTap: () => mapSel.value = LineSel(line),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(children: [
                      LineBadge(line),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text('→ ${titleCase(h)}', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 14, color: t.muted)),
                      ),
                      const SizedBox(width: 8),
                      Text('~${mins(eta)} · ${clockIn(eta)}', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: t.muted)),
                    ]),
                  ),
                ),
              Text('Ώρα αναχώρησης από την αφετηρία + η διαδρομή ως εδώ με μέση ταχύτητα. Όχι live.', style: TextStyle(fontSize: 12, color: t.muted)),
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

typedef _Missed = ({String line, String headsign, String t, PlanEnd end});
