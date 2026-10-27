// A whole line in the map's sheet: its directions with the buses on the road now, and a star that
// makes it one of "my lines". The map draws every direction with its arrows.

import 'dart:async';

import 'package:flutter/material.dart';

import '../core/models.dart';
import 'map_sel.dart';
import 'theme.dart';
import 'widgets.dart';

class LinePanel extends StatefulWidget {
  const LinePanel({super.key, required this.line, required this.scroll});
  final String line;
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
          if (s != null)
            for (final e in s.variants.entries) ...[
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 4),
                child: Text('→ ${titleCase(e.value.headsign)}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              ),
              ..._buses(t, s, e.key, vs.where((v) => v.variant == e.key).toList()),
            ],
          const SizedBox(height: 16),
          const LiveNote(),
        ]);
      },
    );
  }

  List<Widget> _buses(Tones t, LineStatic s, String variant, List<Vehicle> vs) {
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
