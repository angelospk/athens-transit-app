// A whole line in the map's sheet: its directions with the buses on the road now, and a star that
// makes it one of "my lines". The map draws every direction with its arrows; a direction chip keeps
// one direction on the map, with its buses and its stops (a stop opens in the sheet), as on the web.

import 'dart:async';

import 'package:flutter/material.dart';

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
          if (s == null) const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator())),
          if (s != null) ..._directions(t, s, vs),
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
    return [
      chips,
      const SizedBox(height: 8),
      ..._buses(t, s, mine),
      Padding(
        padding: const EdgeInsets.only(top: 14, bottom: 4),
        child: Text('Στάσεις · πάτα μία για τις αφίξεις της', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: t.muted)),
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
              if (delayNote(context, v.delayS) case final n?) Text(n.$1, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: n.$2)),
              Icon(Icons.chevron_right, color: t.muted),
            ]),
          ),
        ),
    ];
  }
}
