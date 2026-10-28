// A tapped station on the map. Suburban rail: the next trains live from railway.gov.gr (time, delay,
// platform, the end of the line from the next stop). Metro and tram: the timetable from our backend
// (STASY GTFS), or a note while the backend does not serve it. Below, the bus stops near the station.

import 'dart:async';

import 'package:flutter/material.dart';

import '../core/athens_time.dart';
import '../core/models.dart';
import '../core/nearby.dart';
import '../core/rail.dart';
import 'map_sel.dart';
import 'stop_screen.dart';
import 'theme.dart';
import 'widgets.dart';

class StationPanel extends StatefulWidget {
  const StationPanel({super.key, required this.sel, required this.ix, required this.scroll});
  final StationSel sel;
  final TripIndex? ix;
  final ScrollController scroll;

  @override
  State<StationPanel> createState() => _StationPanelState();
}

class _StationPanelState extends State<StationPanel> {
  List<RailDeparture>? _trains;
  Suburban? _sub;
  Map<String, dynamic>? _metro; // the backend's answer; null: not loaded or not served
  bool _failed = false, _loaded = false;
  Timer? _timer;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_timer == null) {
      _load();
      _timer = Timer.periodic(const Duration(seconds: 30), (_) => _load());
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    final api = Deps.of(context).api;
    final id = widget.sel.railId;
    var failed = false;
    try {
      if (id != null) {
        _sub ??= await api.suburban();
        _trains = await api.railDepartures(id);
      } else {
        _metro = await api.stasyDepartures(widget.sel.name);
      }
    } catch (_) {
      failed = true; // the last good list stays
    }
    if (!mounted) return;
    setState(() {
      _failed = failed && _trains == null && _metro == null;
      _loaded = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tones;
    final sel = widget.sel;
    final rail = sel.railId != null;
    final ix = widget.ix;
    final stops = ix == null ? const <NearbyStop>[] : nearbyStops(ix, sel.at, radiusM: 400, max: 4);
    return ListView(
      controller: widget.scroll,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      children: [
        const SheetHandle(),
        Row(
          children: [
            const BackSel(),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    rail ? 'Σταθμός Προαστιακού' : 'Σταθμός μετρό / τραμ',
                    style: TextStyle(fontSize: 13, color: t.muted, fontWeight: FontWeight.w500),
                  ),
                  Text(titleCase(sel.name), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            const CloseSel(),
          ],
        ),
        if (sel.lines.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 8),
            child: Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [for (final l in sel.lines) Chip(label: Text(rail ? (_sub?.corridors[l]?.name ?? l) : l), visualDensity: VisualDensity.compact)],
            ),
          ),
        if (!_loaded)
          const Padding(
            padding: EdgeInsets.all(20),
            child: Center(child: CircularProgressIndicator()),
          ),
        if (_loaded && _failed) _note(t, 'Δεν φόρτωσαν οι αναχωρήσεις. Δοκιμάζω ξανά σε λίγο.'),
        if (_loaded && !_failed) ...(rail ? _trainRows(t) : _metroRows(t)),
        if (stops.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            'Στάσεις λεωφορείων κοντά',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: t.muted),
          ),
          for (final s in stops)
            ListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              leading: const Icon(Icons.directions_bus_outlined),
              title: Text(titleCase(s.name)),
              subtitle: Text('${s.distM.round()} μ. · ${s.lines.take(8).join(', ')}', maxLines: 1, overflow: TextOverflow.ellipsis),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => mapSel.value = StopSel(StopRef(name: s.name, lat: s.lat, lon: s.lon, lines: linesAt(ix!, s.name, s.lat, s.lon))),
            ),
        ],
      ],
    );
  }

  Widget _note(Tones t, String s) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 12),
    child: Text(s, style: TextStyle(color: t.muted)),
  );

  // The next trains: expected time (the timetable's crossed out when late), the end of the line, platform.
  List<Widget> _trainRows(Tones t) {
    final now = DateTime.now().toUtc();
    final list = (_trains ?? const <RailDeparture>[])
        .where((d) => d.status != 'completed' && d.expected.isAfter(now.subtract(const Duration(minutes: 1))))
        .toList();
    if (list.isEmpty) return [_note(t, 'Κανένα τρένο στις επόμενες ώρες.')];
    final sub = _sub;
    return [
      for (final d in list)
        DecoratedBox(
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: t.rule)),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              children: [
                SizedBox(
                  width: 64,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _hm(d.expected),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: d.cancelled ? t.muted : ((d.delayMin ?? 0) >= 3 ? t.late : null),
                          decoration: d.cancelled ? TextDecoration.lineThrough : null,
                        ),
                      ),
                      if ((d.delayMin ?? 0) > 0 && !d.cancelled)
                        Text(
                          _hm(d.scheduled),
                          style: TextStyle(fontSize: 12, color: t.muted, decoration: TextDecoration.lineThrough),
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _towards(sub, d),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                      ),
                      Text(
                        [
                          if (d.train.isNotEmpty) 'Τρένο ${d.train}',
                          if (d.cancelled) 'ακυρώθηκε' else if ((d.delayMin ?? 0) > 0) '+${d.delayMin}′ καθυστέρηση' else 'στην ώρα του',
                        ].join(' · '),
                        style: TextStyle(fontSize: 13, color: d.cancelled || (d.delayMin ?? 0) >= 3 ? t.late : t.muted),
                      ),
                    ],
                  ),
                ),
                if (d.platform != null && d.platform!.isNotEmpty)
                  Column(
                    children: [
                      Text('γραμμή', style: TextStyle(fontSize: 11, color: t.muted)),
                      Text(d.platform!, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                    ],
                  ),
              ],
            ),
          ),
        ),
      Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Text(
          'Live από railway.gov.gr. Ο πίνακας δίνει μόνο την επόμενη στάση· το «προς» είναι το τέρμα της γραμμής.',
          style: TextStyle(fontSize: 12, color: t.muted),
        ),
      ),
    ];
  }

  String _towards(Suburban? sub, RailDeparture d) {
    final ends = sub?.towards(widget.sel.railId!, d.next) ?? const <String>{};
    return ends.isNotEmpty ? 'προς ${ends.map(titleCase).join(' / ')}' : 'επόμενη στάση ${titleCase(d.next)}';
  }

  // Metro/tram: the backend's timetable rows (line, headsign, minutes), or why there are none.
  List<Widget> _metroRows(Tones t) {
    final j = _metro;
    if (j == null) return [_note(t, 'Τα δρομολόγια μετρό και τραμ θέλουν τον server μας· δεν τα δίνει ακόμη.')];
    final deps = [for (final d in j['departures'] as List? ?? const []) d as Map<String, dynamic>];
    if (deps.isEmpty) return [_note(t, 'Καμία αναχώρηση στην επόμενη ώρα.')];
    return [
      for (final d in deps)
        DecoratedBox(
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: t.rule)),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: _color(d['route_color'] as String?) ?? t.ink, borderRadius: BorderRadius.circular(6)),
                  child: Text(
                    '${d['line'] ?? ''}',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'προς ${titleCase('${d['headsign'] ?? ''}')}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 15),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(mins(((d['in_s'] as num?) ?? 0).toInt()), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                    Text(gtfsClock('${d['t'] ?? ''}'), style: TextStyle(fontSize: 12, color: t.muted)),
                  ],
                ),
              ],
            ),
          ),
        ),
      Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Text(
          j['indicative'] == true ? 'Ενδεικτικά, από το πρόγραμμα της ΣΤΑΣΥ (όχι live).' : 'Από το πρόγραμμα της ΣΤΑΣΥ (όχι live).',
          style: TextStyle(fontSize: 12, color: t.muted),
        ),
      ),
    ];
  }

  String _hm(DateTime utc) {
    final w = athensWall(utc);
    return '${w.hour.toString().padLeft(2, '0')}:${w.minute.toString().padLeft(2, '0')}';
  }

  Color? _color(String? hex) {
    if (hex == null || hex.isEmpty) return null;
    final v = int.tryParse(hex.replaceFirst('#', ''), radix: 16);
    return v == null ? null : Color(0xFF000000 | v);
  }
}
