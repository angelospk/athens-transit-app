// Screen 12 · Λεωφορείο: one bus — delay, speed now against the usual, GPS age, and the next stops.
// The content of the map's sheet; the map draws the bus's route with its direction arrows.

import 'dart:async';

import 'package:flutter/material.dart';

import '../core/eta.dart';
import '../core/models.dart';
import '../core/nearby.dart';
import '../data/live.dart';
import 'alert_sheet.dart';
import 'line_speed.dart';
import 'ride.dart';
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
            Row(children: [const BackSel(), LineBadge(widget.line), const Spacer(), const CloseSel()]),
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
    int kmh(double ms) => (ms * 3.6).round();
    final slow = v.speed != null && usual != null && v.speed! < usual * .6;
    final muted = TextStyle(fontSize: 13.5, color: t.muted);
    // The next stops: the ones the bus has passed since its fix (they read "τώρα") are left out.
    final etas = nextK < 0 ? const <int?>[] : [for (var k = nextK; k < stops.length; k++) etaSeconds(s, v, k, now)];
    final from = nextK < 0 ? 0 : nextK + firstUpcoming(etas);
    final variants = v.variant == null ? null : {v.variant!};
    // The big number: minutes to the user's stop if the bus still reaches it, else to its next stop.
    final mineK = nextK < 0 ? -1 : [for (var k = from; k < stops.length; k++) k].firstWhere((k) => myIds.contains(stops[k]), orElse: () => -1);
    final headK = mineK >= 0 ? mineK : (nextK < 0 || from >= stops.length ? -1 : from);
    final headEta = headK < 0 ? null : etas[headK - nextK];
    final headName = headK < 0 ? '' : titleCase(s.stops[stops[headK]]?.name ?? stops[headK]);
    final late = delay != null && delay >= 90;
    return ListView(controller: widget.scroll, padding: const EdgeInsets.fromLTRB(16, 0, 16, 24), children: [
      const SheetHandle(),
      Row(children: [
        const BackSel(),
        LineButton(widget.line, variants: variants),
        const SizedBox(width: 12),
        Expanded(
          child: Text('→ ${titleCase(variant?.headsign ?? '')}', maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.titleLarge),
        ),
        const CloseSel(),
      ]),
      const SizedBox(height: 8),
      if (headEta != null)
        Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text(mins(headEta), style: const TextStyle(fontSize: 40, height: 1, fontWeight: FontWeight.w700, fontFeatures: [FontFeature.tabularFigures()])),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(mineK >= 0 ? 'στη στάση σου · $headName' : 'στην επόμενη στάση · $headName',
                  maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              if (delay != null)
                Text(delayWords(delay), style: TextStyle(fontSize: 14, fontWeight: late ? FontWeight.w700 : FontWeight.w400, color: late ? t.late : t.onTime)),
            ]),
          ),
        ]),
      const SizedBox(height: 12),
      Row(children: [
        Expanded(
          child: FilledButton.icon(
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(46)),
            icon: const Icon(Icons.notifications_outlined),
            label: const Text('Ειδοποίησέ με'),
            onPressed: nextK < 0 ? null : () => _pickAlert(s, v, stops, from, myIds),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(46)),
            icon: const Icon(Icons.flag_outlined),
            label: const Text('Πού κατεβαίνω;'),
            onPressed: nextK < 0 ? null : () => showRide(context, line: widget.line, st: s, vehicle: v),
          ),
        ),
      ]),
      // Speed, position age, the vehicle and its timetable run: folded, they are for the curious.
      Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: EdgeInsets.zero,
          childrenPadding: const EdgeInsets.only(bottom: 8),
          expandedAlignment: Alignment.centerLeft,
          title: Text('Λεπτομέρειες', style: TextStyle(fontSize: 14, color: t.muted)),
          children: [
            Wrap(crossAxisAlignment: WrapCrossAlignment.center, spacing: 6, runSpacing: 2, children: [
              Text(v.speed == null ? '— χλμ/ώ' : '${kmh(v.speed!)} χλμ/ώ', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: slow ? t.late : t.ink)),
              InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () => showLineSpeed(context, line: widget.line, vehicle: v),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Text(usual == null ? 'ταχύτητες γραμμής' : 'συνήθως ${kmh(usual)}',
                        style: TextStyle(fontSize: 13.5, color: t.ink, decoration: TextDecoration.underline, decorationColor: t.muted)),
                    Icon(Icons.chevron_right, size: 16, color: t.muted),
                  ]),
                ),
              ),
              Text('·', style: muted),
              Text('θέση πριν ${ago(age)}', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: age <= 90 ? t.onTime : t.late)),
              Text('·', style: muted),
              Text('όχημα ${v.id}', style: muted),
            ]),
            if (v.tripLabel != null) Text('δρομολόγιο ${v.tripLabel}', style: muted),
          ],
        ),
      ),
      Text('Επόμενες στάσεις', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: t.muted)),
      const SizedBox(height: 4),
      if (nextK >= 0)
        for (var k = from; k < stops.length && (allStops || k < from + 8); k++)
          _stopRow(t, s, stops, k, etas[k - nextK], myIds.contains(stops[k])),
      if (nextK >= 0 && !allStops && stops.length > from + 8)
        TextButton(onPressed: () => setState(() => allStops = true), child: Text('Όλες οι επόμενες (${stops.length - from})')),
      if (nextK < 0) Text('Το λεωφορείο δεν έχει αντιστοιχιστεί σε δρομολόγιο.', style: TextStyle(color: t.muted)),
    ]);
  }

  Widget _stopRow(Tones t, LineStatic s, List<String> stops, int k, int? eta, bool mine) {
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
          if (eta != null) ...[
            Text(mins(eta), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, fontFeatures: [FontFeature.tabularFigures()])),
            SizedBox(
              width: 52,
              child: Text(clockIn(eta), textAlign: TextAlign.right, style: TextStyle(fontSize: 13, color: t.muted, fontFeatures: const [FontFeature.tabularFigures()])),
            ),
          ],
        ]),
      ),
    );
  }

  // "Ειδοποίησέ με": first where (the bus's next stops; the stop it was opened from on top), then when
  // (the alert sheet).
  Future<void> _pickAlert(LineStatic s, Vehicle v, List<String> stops, int from, Set<String> myIds) async {
    final now = Deps.of(context).live.nowS;
    final t = context.tones;
    final ks = [for (var k = from; k < stops.length; k++) k];
    final mine = ks.where((k) => myIds.contains(stops[k])).toList();
    final order = [...mine, ...ks.where((k) => !mine.contains(k))];
    final k = await showModalBottomSheet<int>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (c) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: .6,
        maxChildSize: .9,
        builder: (c, scroll) => ListView(controller: scroll, padding: const EdgeInsets.fromLTRB(16, 0, 16, 16), children: [
          const Text('Σε ποια στάση;', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
          Text('Σε ειδοποιώ πριν φτάσει εκεί το λεωφορείο.', style: TextStyle(fontSize: 13, color: t.muted)),
          const SizedBox(height: 8),
          for (final k in order)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(myIds.contains(stops[k]) ? Icons.star : Icons.circle_outlined, size: 18),
              title: Text(titleCase(s.stops[stops[k]]?.name ?? stops[k]), style: TextStyle(fontWeight: myIds.contains(stops[k]) ? FontWeight.w700 : FontWeight.w400)),
              trailing: Text(switch (etaSeconds(s, v, k, now)) { final e? => '${mins(e)} · ${clockIn(e)}', null => '' }),
              onTap: () => Navigator.pop(c, k),
            ),
        ]),
      ),
    );
    if (k != null && mounted) _alertAt(s, v, stops[k], now);
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
