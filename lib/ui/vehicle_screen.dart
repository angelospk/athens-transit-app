// Screen 12 · Λεωφορείο: one bus — delay, speed now against the usual, GPS age, and the next stops.
// The content of the map's sheet; the map draws the bus's route with its direction arrows.

import 'dart:async';

import 'package:flutter/material.dart';

import '../core/eta.dart';
import '../core/models.dart';
import '../core/nearby.dart';
import '../data/live.dart';
import 'alert_sheet.dart';
import 'map_sel.dart';
import 'stop_screen.dart';
import 'theme.dart';
import 'widgets.dart';

class VehiclePanel extends StatefulWidget {
  const VehiclePanel({super.key, required this.line, required this.vehicleId, this.stop, required this.scroll});
  final String line, vehicleId;
  final StopRef? stop;
  final ScrollController scroll;

  @override
  State<VehiclePanel> createState() => _VehiclePanelState();
}

class _VehiclePanelState extends State<VehiclePanel> {
  LineLive? live;
  LineStatic? st;
  Object? error;
  bool allStops = false;
  Timer? _timer;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // A line the hub does not poll is asked again every 15 s: the bus moves on, and a failed load (no
    // network) recovers by itself.
    _timer ??= Timer.periodic(const Duration(seconds: 15), (_) {
      if (!Deps.of(context).live.lives.containsKey(widget.line) || error != null) _load();
    });
    if (st == null) _load();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  void didUpdateWidget(VehiclePanel old) {
    super.didUpdateWidget(old);
    if (old.line != widget.line) {
      st = null;
      live = null;
      error = null;
      _load();
    }
  }

  Future<void> _load() async {
    final d = Deps.of(context);
    try {
      final s = st ?? await d.api.lineStatic(widget.line);
      final l = d.live.lives[widget.line] ?? await d.api.live(widget.line);
      if (mounted) {
        setState(() {
          st = s;
          live = l;
          error = null;
        });
      }
    } catch (e) {
      if (mounted) setState(() => error = e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tones;
    final d = Deps.of(context);
    return ListenableBuilder(
      listenable: d.live,
      builder: (context, _) {
        final l = d.live.lives[widget.line] ?? live;
        final v = l?.vehicles.where((x) => x.id == widget.vehicleId).firstOrNull;
        final s = st;
        if (s == null || v == null) {
          return ListView(controller: widget.scroll, padding: const EdgeInsets.fromLTRB(16, 0, 16, 24), children: [
            const SheetHandle(),
            Row(children: [_back(), LineBadge(widget.line), const Spacer(), const CloseSel()]),
            if (error == null && (l == null || s == null))
              const Padding(padding: EdgeInsets.symmetric(vertical: 24), child: Center(child: CircularProgressIndicator()))
            else ...[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(
                    error != null
                        ? 'Δεν φορτώνει το λεωφορείο: χωρίς σύνδεση. Ξαναδοκιμάζω σε λίγο.'
                        : 'Το λεωφορείο #${widget.vehicleId} δεν στέλνει θέση τώρα: μάλλον τελείωσε το δρομολόγιό του.',
                    style: TextStyle(fontSize: 15, color: t.muted)),
              ),
              FilledButton.tonal(onPressed: () => mapSel.value = LineSel(widget.line), child: Text('Δες τα λεωφορεία του ${widget.line}')),
            ],
          ]);
        }
        return _details(context, t, s, v, d.live.nowS);
      },
    );
  }

  Widget _details(BuildContext context, Tones t, LineStatic s, Vehicle v, int now) {
    final variant = s.variants[v.variant];
    final stops = variant?.stops ?? const <String>[];
    final nextK = v.nextStopId == null ? -1 : stops.indexOf(v.nextStopId!);
    final myIds = widget.stop == null ? <String>{} : stopIdsNear(s, widget.stop!.name, widget.stop!.lat, widget.stop!.lon).toSet();
    final usual = v.pathSpeeds?.firstWhere((x) => x != null, orElse: () => null);
    final age = now - v.positionAt;
    final delay = v.delayS;
    Widget cell(String a, String b, String c, Color cc) => Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(color: t.surface, borderRadius: BorderRadius.circular(14)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(a, style: TextStyle(fontSize: 12, color: t.muted)),
              Text(b, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
              Text(c, style: TextStyle(fontSize: 12, color: cc, fontWeight: FontWeight.w600)),
            ]),
          ),
        );
    int kmh(double ms) => (ms * 3.6).round();
    return ListView(controller: widget.scroll, padding: const EdgeInsets.fromLTRB(16, 0, 16, 24), children: [
      const SheetHandle(),
      Row(children: [
        _back(),
        LineBadge(widget.line),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('→ ${titleCase(variant?.headsign ?? '')}', maxLines: 2, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.titleLarge),
            if (v.tripLabel != null) Text('δρομολόγιο ${v.tripLabel}', style: TextStyle(fontSize: 13, color: t.muted)),
          ]),
        ),
        if (delay != null)
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(delay.abs() < 60 ? '0′' : '${delay > 0 ? '+' : '−'}${(delay.abs() / 60).round()}′',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: delay >= 90 ? t.late : t.onTime)),
            Text('από πρόγραμμα', style: TextStyle(fontSize: 12, color: t.muted)),
          ]),
        const CloseSel(),
      ]),
      const SizedBox(height: 14),
      Row(children: [
        cell('Τώρα', v.speed == null ? '—' : '${kmh(v.speed!)} χλμ/ώ', usual == null ? '' : 'συνήθως ${kmh(usual)}',
            v.speed != null && usual != null && v.speed! < usual * .6 ? t.late : t.muted),
        const SizedBox(width: 8),
        cell('GPS', 'πριν ${age < 60 ? '$age″' : '${age ~/ 60}′'}', age <= 90 ? 'φρέσκο' : 'παλιό', age <= 90 ? t.onTime : t.late),
        const SizedBox(width: 8),
        cell('Όχημα', '#${v.id}', '', t.muted),
      ]),
      if (widget.stop != null) ...[
        const SizedBox(height: 14),
        SizedBox(
          height: 48,
          width: double.infinity,
          child: FilledButton.icon(
            icon: const Icon(Icons.notifications_outlined),
            label: Text('Ειδοποίησέ με πριν φτάσει στο ${titleCase(widget.stop!.name)}', overflow: TextOverflow.ellipsis),
            onPressed: () {
              final arr = arrivalsAt(myIds.isEmpty ? '' : myIds.first, {widget.line: s}, {widget.line: LineLive(line: widget.line, updatedAt: now, nextUpdateAt: now, vehicles: [v])}, now);
              if (arr.isNotEmpty) showAlertSheet(context, stop: widget.stop!, arrival: arr.first);
            },
          ),
        ),
      ],
      const SizedBox(height: 4),
      // The map keeps this bus in the middle while the sheet shows it.
      ValueListenableBuilder(
        valueListenable: followBus,
        builder: (context, on, _) => SwitchListTile(
          contentPadding: EdgeInsets.zero,
          secondary: const Icon(Icons.my_location),
          title: const Text('Ο χάρτης ακολουθεί το λεωφορείο'),
          value: on,
          onChanged: (x) => followBus.value = x,
        ),
      ),
      Row(children: [
        Expanded(child: Text('Επόμενες στάσεις · πάτα μία για τις αφίξεις της', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: t.muted))),
        TextButton(onPressed: () => mapSel.value = LineSel(widget.line, variants: v.variant == null ? null : {v.variant!}), child: const Text('Η γραμμή')),
      ]),
      if (nextK >= 0)
        for (var k = nextK; k < stops.length && (allStops || k < nextK + 8); k++)
          _stopRow(t, s, v, stops, k, now, myIds.contains(stops[k])),
      if (nextK >= 0 && !allStops && stops.length > nextK + 8)
        TextButton(onPressed: () => setState(() => allStops = true), child: Text('Όλες οι επόμενες (${stops.length - nextK})')),
      if (nextK < 0) Text('Το λεωφορείο δεν έχει αντιστοιχιστεί σε δρομολόγιο.', style: TextStyle(color: t.muted)),
    ]);
  }

  // Back to the stop the bus was opened from.
  Widget _back() => widget.stop == null
      ? const SizedBox.shrink()
      : IconButton(tooltip: 'Πίσω στη στάση', icon: const Icon(Icons.arrow_back), onPressed: () => mapSel.value = StopSel(widget.stop!));

  Widget _stopRow(Tones t, LineStatic s, Vehicle v, List<String> stops, int k, int now, bool mine) {
    final eta = etaSeconds(s, v, k, now);
    final info = s.stops[stops[k]];
    final name = titleCase(info?.name ?? stops[k]);
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: info == null ? null : () => _openStop(info),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 1),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: mine ? BoxDecoration(color: t.indicator, borderRadius: BorderRadius.circular(12)) : null,
        child: Row(children: [
        Icon(Icons.circle_outlined, size: mine ? 16 : 12, color: mine ? t.ink : palette[0].bg),
        const SizedBox(width: 12),
        Expanded(child: Text(mine ? '$name · η στάση σου' : name, style: TextStyle(fontSize: 15, fontWeight: mine ? FontWeight.w700 : FontWeight.w400))),
        Text(eta == null ? '' : mins(eta), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
        if (eta != null) ...[
          const SizedBox(width: 4),
          IconButton(
            tooltip: 'Ειδοποίησέ με πριν φτάσει στο $name',
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.notifications_outlined, size: 20),
            onPressed: () => _alertAt(s, v, stops[k], now),
          ),
        ],
      ]),
      ),
    );
  }

  // A stop of the bus's way opens in the sheet with every line that stops there.
  Future<void> _openStop(StopInfo info) async {
    final from = widget.stop;
    if (from != null && from.name == info.name) {
      mapSel.value = StopSel(from);
      return;
    }
    final ix = await Deps.of(context).api.trips();
    final all = linesAt(ix, info.name, info.lat, info.lon);
    mapSel.value = StopSel(StopRef(name: info.name, lat: info.lat, lon: info.lon, lines: all.isEmpty ? [widget.line] : all));
  }

  // An alert is about a stop: this bus's arrival at the stop of the row.
  void _alertAt(LineStatic s, Vehicle v, String stopId, int now) {
    final info = s.stops[stopId];
    if (info == null) return;
    final arr = arrivalsAt(stopId, {widget.line: s}, {widget.line: LineLive(line: widget.line, updatedAt: now, nextUpdateAt: now, vehicles: [v])}, now);
    if (arr.isEmpty) return;
    final from = widget.stop; // the stop the bus was opened from keeps its full line list
    final same = from != null && stopIdsNear(s, from.name, from.lat, from.lon).contains(stopId);
    showAlertSheet(context, stop: same ? from : StopRef(name: info.name, lat: info.lat, lon: info.lon, lines: [widget.line]), arrival: arr.first);
  }
}
