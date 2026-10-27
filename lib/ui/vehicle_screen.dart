// Screen 12 · Λεωφορείο: one bus — delay, speed now against the usual, GPS age, and the next stops.

import 'package:flutter/material.dart';

import '../core/eta.dart';
import '../core/models.dart';
import '../data/live.dart';
import 'alert_sheet.dart';
import 'stop_screen.dart';
import 'theme.dart';
import 'widgets.dart';

class VehicleScreen extends StatefulWidget {
  const VehicleScreen({super.key, required this.line, required this.vehicleId, this.stop});
  final String line, vehicleId;
  final StopRef? stop;

  @override
  State<VehicleScreen> createState() => _VehicleScreenState();
}

class _VehicleScreenState extends State<VehicleScreen> {
  LineLive? live;
  LineStatic? st;
  Object? error;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (st == null) _load();
  }

  Future<void> _load() async {
    final d = Deps.of(context);
    try {
      final s = await d.api.lineStatic(widget.line);
      final l = d.live.lives[widget.line] ?? await d.api.live(widget.line);
      if (mounted) {
        setState(() {
          st = s;
          live = l;
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
        Widget body;
        if (s == null || v == null) {
          body = Center(child: error != null ? const Text('Δεν βρέθηκε το λεωφορείο.') : const CircularProgressIndicator());
        } else {
          body = _details(context, t, s, v, d.live.nowS);
        }
        return Scaffold(appBar: AppBar(backgroundColor: t.ground, surfaceTintColor: Colors.transparent), body: body);
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
    return ListView(padding: const EdgeInsets.fromLTRB(16, 0, 16, 24), children: [
      Row(children: [
        LineBadge(widget.line),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('→ ${titleCase(variant?.headsign ?? '')}', style: Theme.of(context).textTheme.titleLarge),
            if (v.tripLabel != null) Text('δρομολόγιο ${v.tripLabel}', style: TextStyle(fontSize: 13, color: t.muted)),
          ]),
        ),
        if (delay != null)
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(delay.abs() < 60 ? '0′' : '${delay > 0 ? '+' : '−'}${(delay.abs() / 60).round()}′',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, color: delay >= 90 ? t.late : t.onTime)),
            Text('από πρόγραμμα', style: TextStyle(fontSize: 12, color: t.muted)),
          ]),
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
      const SizedBox(height: 14),
      if (nextK >= 0)
        for (var k = nextK; k < stops.length && k < nextK + 8; k++)
          _stopRow(t, s, v, stops, k, now, myIds.contains(stops[k])),
      if (nextK < 0) Text('Το λεωφορείο δεν έχει αντιστοιχιστεί σε δρομολόγιο.', style: TextStyle(color: t.muted)),
      const SizedBox(height: 16),
      if (widget.stop != null)
        SizedBox(
          height: 48,
          child: FilledButton(
            onPressed: () {
              final arr = arrivalsAt(myIds.isEmpty ? '' : myIds.first, {widget.line: s}, {widget.line: LineLive(line: widget.line, updatedAt: now, nextUpdateAt: now, vehicles: [v])}, now);
              if (arr.isNotEmpty) showAlertSheet(context, stop: widget.stop!, arrival: arr.first);
            },
            child: const Text('Ειδοποίησέ με'),
          ),
        ),
    ]);
  }

  Widget _stopRow(Tones t, LineStatic s, Vehicle v, List<String> stops, int k, int now, bool mine) {
    final eta = etaSeconds(s, v, k, now);
    final name = titleCase(s.stops[stops[k]]?.name ?? stops[k]);
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 1),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: mine ? BoxDecoration(color: t.indicator, borderRadius: BorderRadius.circular(12)) : null,
      child: Row(children: [
        Icon(Icons.circle_outlined, size: mine ? 16 : 12, color: mine ? t.ink : palette[0].bg),
        const SizedBox(width: 12),
        Expanded(child: Text(mine ? '$name · η στάση σου' : name, style: TextStyle(fontSize: 15, fontWeight: mine ? FontWeight.w700 : FontWeight.w400))),
        Text(eta == null ? '' : mins(eta), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
      ]),
    );
  }
}
