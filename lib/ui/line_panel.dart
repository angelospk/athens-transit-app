// A whole line in the map's sheet: its directions with the buses on the road now, and a star that
// makes it one of "my lines". The map draws every direction with its arrows; a direction chip keeps
// one direction on the map, with its buses and its stops (a stop opens in the sheet), as on the web.
// «Δρομολόγια»: today's timetable by direction, the runs already gone marked as seen or missed.

import 'dart:async';

import 'package:flutter/material.dart';

import '../core/athens_time.dart';
import '../core/eta.dart';
import '../core/models.dart';
import '../core/nearby.dart';
import 'map_sel.dart';
import 'stop_screen.dart';
import 'theme.dart';
import 'widgets.dart';

class LinePanel extends StatefulWidget {
  const LinePanel({super.key, required this.line, this.variants, required this.scroll});
  final String line;
  final Set<String>? variants; // the direction on the map; null: all
  final ScrollController scroll;

  @override
  State<LinePanel> createState() => _LinePanelState();
}

class _LinePanelState extends State<LinePanel> {
  LineStatic? st;
  LineLive? live;
  String name = '';
  Timer? _timer;
  bool _timetable = false;
  Future<Map<String, dynamic>?>? _sched;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _timer ??= Timer.periodic(const Duration(seconds: 30), (_) => _loadLive());
    if (st == null) _load();
  }

  @override
  void didUpdateWidget(LinePanel old) {
    super.didUpdateWidget(old);
    if (old.line != widget.line) {
      st = null;
      live = null;
      name = '';
      _sched = _timetable ? Deps.of(context).api.lineSchedule(widget.line) : null;
      _load();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    final api = Deps.of(context).api;
    final line = widget.line;
    try {
      final s = await api.lineStatic(line);
      if (!mounted || line != widget.line) return;
      setState(() => st = s);
      final info = (await api.lines()).where((l) => l.id == line).firstOrNull;
      if (mounted && line == widget.line) setState(() => name = info?.name ?? '');
    } catch (_) {/* the header still shows the line */}
    if (mounted) await _loadLive();
  }

  Future<void> _loadLive() async {
    final d = Deps.of(context);
    final line = widget.line;
    if (d.store.myLines.contains(line)) return; // one of my lines: the hub polls it
    try {
      final l = await d.api.live(line);
      if (mounted && line == widget.line) setState(() => live = l);
    } catch (_) {/* kept until the next poll */}
  }

  @override
  Widget build(BuildContext context) {
    final d = Deps.of(context);
    final t = context.tones;
    return ListenableBuilder(
      listenable: Listenable.merge([d.store, d.live]),
      builder: (context, _) {
        final mine = d.store.myLines.contains(widget.line);
        final vs = (mine ? d.live.lives[widget.line] ?? live : live)?.vehicles ?? const <Vehicle>[];
        final s = st;
        return ListView(controller: widget.scroll, padding: const EdgeInsets.fromLTRB(16, 0, 16, 24), children: [
          const SheetHandle(),
          Row(children: [
            const BackSel(),
            LineBadge(widget.line, big: true),
            const SizedBox(width: 12),
            Expanded(
              child: Text(titleCase(name), maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ),
            IconButton.filledTonal(
              tooltip: mine ? 'Βγάλε από τις γραμμές μου' : 'Στις γραμμές μου',
              isSelected: mine,
              icon: const Icon(Icons.star_outline),
              selectedIcon: const Icon(Icons.star),
              onPressed: () {
                if (mine) live = d.live.lives[widget.line]; // no longer polled by the hub: the panel polls it
                if (!d.store.toggleMyLine(widget.line)) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ως 5 γραμμές. Βγάλε μία από τις γραμμές σου πρώτα.')));
                }
              },
            ),
            const CloseSel(),
          ]),
          const SizedBox(height: 8),
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(value: false, label: Text('Τώρα'), icon: Icon(Icons.directions_bus_outlined)),
              ButtonSegment(value: true, label: Text('Δρομολόγια'), icon: Icon(Icons.schedule)),
            ],
            selected: {_timetable},
            showSelectedIcon: false,
            onSelectionChanged: (v) => setState(() {
              _timetable = v.first;
              if (_timetable) _sched ??= d.api.lineSchedule(widget.line);
            }),
          ),
          const SizedBox(height: 8),
          if (_timetable) _schedule(t),
          if (!_timetable && s == null) const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator())),
          if (!_timetable && s != null) ..._directions(t, s, vs),
          const SizedBox(height: 16),
          const LiveNote(),
        ]);
      },
    );
  }

  // Directions by headsign (a line may run several variants to the same end). All of them: each with
  // its buses. One picked: its buses and every stop on its way.
  List<Widget> _directions(Tones t, LineStatic s, List<Vehicle> vs) {
    final groups = <String, Set<String>>{};
    for (final e in s.variants.entries) {
      (groups[e.value.headsign] ??= {}).add(e.key);
    }
    final picked = widget.variants;
    final on = picked == null ? null : groups.entries.where((g) => g.value.any(picked.contains)).firstOrNull;
    void pick(Set<String>? v) => mapSel.value = LineSel(widget.line, variants: v);
    final chips = Wrap(spacing: 8, runSpacing: 4, children: [
      ChoiceChip(label: const Text('Όλες'), selected: on == null, onSelected: (_) => pick(null)),
      for (final g in groups.entries)
        ChoiceChip(label: Text('→ ${titleCase(g.key)}'), selected: on?.key == g.key, onSelected: (_) => pick(g.value)),
    ]);
    if (on == null) {
      return [
        chips,
        for (final g in groups.entries) ...[
          InkWell(
            onTap: () => pick(g.value),
            child: Padding(
              padding: const EdgeInsets.only(top: 14, bottom: 4),
              child: Row(children: [
                Expanded(child: Text('→ ${titleCase(g.key)}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700))),
                Text('στάσεις', style: TextStyle(fontSize: 13, color: t.muted)),
                Icon(Icons.chevron_right, size: 18, color: t.muted),
              ]),
            ),
          ),
          ..._buses(t, s, vs.where((v) => g.value.contains(v.variant)).toList()),
        ],
      ];
    }
    // The longest variant of the direction lists its stops; a bus shows at the stop it goes to next.
    final main = on.value.reduce((a, b) => s.variants[a]!.stops.length >= s.variants[b]!.stops.length ? a : b);
    final mine = vs.where((v) => on.value.contains(v.variant)).toList();
    final busAt = {for (final v in mine) ?v.nextStopId};
    final order = s.variants[main]!.stops;
    int at(Vehicle v) => v.nextStopId == null ? -1 : order.indexOf(v.nextStopId!);
    mine.sort((a, b) => at(b).compareTo(at(a))); // the front bus first, as the gaps count
    final gaps = busGaps([for (final v in mine) if (v.nextStopId case final id? when order.contains(id)) order.indexOf(id)]);
    final big = bigGap(gaps);
    return [
      chips,
      const SizedBox(height: 8),
      ..._buses(t, s, mine),
      if (gaps.isNotEmpty)
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(
            'Κενά από το μπροστινό: ${gaps.join(' · ')} στάσεις${big == null ? '' : ' · μεγάλο κενό μετά το ${big + 1}ο λεωφορείο'}',
            style: TextStyle(fontSize: 13, color: big == null ? t.muted : t.late),
          ),
        ),
      Padding(
        padding: const EdgeInsets.only(top: 14, bottom: 4),
        child: Text('Στάσεις', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: t.muted)),
      ),
      for (final id in s.variants[main]!.stops)
        if (s.stops[id] case final st?)
          InkWell(
            onTap: () async {
              final d = Deps.of(context);
              final ix = await d.api.trips();
              final all = linesAt(ix, st.name, st.lat, st.lon);
              mapSel.value = StopSel(StopRef(name: st.name, lat: st.lat, lon: st.lon, lines: all.isEmpty ? [widget.line] : all));
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 9),
              child: Row(children: [
                Icon(busAt.contains(id) ? Icons.directions_bus : Icons.circle_outlined, size: busAt.contains(id) ? 18 : 12, color: busAt.contains(id) ? t.ink : t.muted),
                const SizedBox(width: 12),
                Expanded(child: Text(titleCase(st.name), style: const TextStyle(fontSize: 15))),
                Icon(Icons.chevron_right, size: 18, color: t.muted),
              ]),
            ),
          ),
    ];
  }

  // Today's runs by direction: the next ones bold, those gone muted, a missed one (no bus seen) struck.
  Widget _schedule(Tones t) => FutureBuilder<Map<String, dynamic>?>(
        future: _sched,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) return const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator()));
          final j = snap.data;
          if (snap.hasError || j == null) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(snap.hasError ? 'Δεν φόρτωσαν τα δρομολόγια.' : 'Τα δρομολόγια θέλουν τον server μας· δεν τα δίνει ακόμη.', style: TextStyle(color: t.muted)),
            );
          }
          final wall = athensWall(DateTime.now().toUtc());
          final nowMin = wall.hour * 60 + wall.minute;
          int minOf(String hm) {
            final p = hm.split(':');
            return p.length < 2 ? 0 : (int.tryParse(p[0]) ?? 0) * 60 + (int.tryParse(p[1]) ?? 0);
          }

          final dirs = [for (final x in j['directions'] as List? ?? const []) x as Map<String, dynamic>];
          if (dirs.isEmpty) return Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Text('Κανένα δρομολόγιο σήμερα.', style: TextStyle(color: t.muted)));
          return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            if (j['expired'] == true)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text('Το πρόγραμμα του ΟΑΣΑ έχει λήξει: οι ώρες είναι της ίδιας μέρας της εβδομάδας από το παλιό.', style: TextStyle(fontSize: 13, color: t.late)),
              ),
            for (final dir in dirs) ...() {
              final deps = [for (final x in dir['departures'] as List? ?? const []) x as Map<String, dynamic>];
              final gone = deps.where((x) => minOf(x['t'] as String? ?? '') < nowMin).toList();
              final seen = gone.where((x) => x['seen'] == true).length, known = gone.where((x) => x['seen'] != null).length;
              return [
                Padding(
                  padding: const EdgeInsets.only(top: 12, bottom: 2),
                  child: Text('→ ${titleCase(dir['headsign'] as String? ?? '')}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                ),
                Text(
                  [
                    '${deps.length} δρομολόγια σήμερα',
                    if (known > 0) 'έγιναν $seen από $known ως τώρα',
                  ].join(' · '),
                  style: TextStyle(fontSize: 13, color: known > 0 && seen < known ? t.late : t.muted),
                ),
                const SizedBox(height: 6),
                Wrap(spacing: 10, runSpacing: 4, children: [
                  for (final x in deps)
                    () {
                      final hm = x['t'] as String? ?? '';
                      final past = minOf(hm) < nowMin;
                      final missed = past && x['seen'] == false;
                      final shown = gtfsClock(hm);
                      return Text(shown,
                          style: TextStyle(
                            fontSize: 15,
                            fontFeatures: const [FontFeature.tabularFigures()],
                            fontWeight: past ? FontWeight.w400 : FontWeight.w600,
                            color: missed ? t.late : (past ? t.muted : null),
                            decoration: missed ? TextDecoration.lineThrough : null,
                          ));
                    }(),
                ]),
              ];
            }(),
            const SizedBox(height: 10),
            Text(
                j['source'] == 'oasa-daily'
                    ? 'Πρόγραμμα ημέρας ΟΑΣΑ, ώρα αναχώρησης από την αφετηρία.' // no seen flags: OASA runs are not matched
                    : 'Πρόγραμμα ΟΑΣΑ (GTFS), ώρα αναχώρησης από την αφετηρία. Διαγραμμένη: δεν φάνηκε λεωφορείο.',
                style: TextStyle(fontSize: 12, color: t.muted)),
          ]);
        },
      );

  List<Widget> _buses(Tones t, LineStatic s, List<Vehicle> vs) {
    if (vs.isEmpty) return [Text('Κανένα λεωφορείο με GPS τώρα.', style: TextStyle(fontSize: 13, color: t.muted))];
    return [
      for (final v in vs)
        InkWell(
          onTap: () => mapSel.value = BusSel(widget.line, v.id, at: (v.lat, v.lon), variant: v.variant),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(children: [
              Icon(Icons.directions_bus, size: 18, color: t.muted),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  v.nextStopId == null ? 'λεωφορείο #${v.id}' : 'επόμενη: ${titleCase(s.stops[v.nextStopId]?.name ?? '')}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Traffic ahead: the typical speed of the next 2 km (path_speeds) under 10 km/h somewhere.
              if (slowAheadM(v.pathSpeeds) case final m?)
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Text(m == 0 ? 'αργό κομμάτι' : 'αργό σε $m μ.', style: TextStyle(fontSize: 12, color: t.late)),
                ),
              if (delayNote(context, v.delayS) case final n?) Text(n.$1, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: n.$2)),
              Icon(Icons.chevron_right, color: t.muted),
            ]),
          ),
        ),
    ];
  }
}
