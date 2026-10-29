// Screen 17 · Πού κατεβαίνω;: on a bus, pick where you get off; the phone vibrates one stop before
// ("Κατέβα στην επόμενη"). A one-off rule for this bus only, watched by the background service as any
// alert, so it works with the screen off and without a network for a while (offline estimate).

import 'package:flutter/material.dart';

import '../background/service.dart';
import '../core/eta.dart';
import '../core/geo.dart';
import '../core/models.dart';
import '../core/nearby.dart' show fold;
import '../core/rules.dart';
import '../data/locate.dart';
import 'map_sel.dart';
import 'theme.dart';
import 'widgets.dart';

/// «Πού κατεβαίνω;» on a planned trip: a ride alert for the stop to get off at ([alight], by name). The bus
/// is the one of this direction nearest the phone now (the one counted on has usually left the stop
/// by then); none or two of them: the line on the map, to pick it there.
Future<void> rideFromHere(BuildContext context, {required String line, required String variant, required String alight}) async {
  final d = Deps.of(context);
  final me = await myPosition(fresh: true);
  Vehicle? bus;
  if (me != null) {
    try {
      // The line's own feed: tile vehicles have no next stop, which the ride alert needs.
      final live = await d.api.live(line);
      d.live.statics[line] ??= await d.api.lineStatic(line);
      // Fresh fixes of this direction within 250 m; two of them (bunched buses): ask on the map.
      final now = d.live.nowS;
      final near = [
        for (final v in live.vehicles)
          if (v.variant == variant && v.nextStopId != null && now - v.positionAt <= 120 && distM(me, (v.lat, v.lon)) <= 250) v,
      ];
      if (near.length == 1) bus = near.single;
    } catch (_) {/* offline: the line's sheet instead */}
  }
  final st = d.live.statics[line];
  if (!context.mounted) return;
  if (st == null || bus == null) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Δεν βρήκα το λεωφορείο δίπλα σου. Διάλεξέ το στον χάρτη και πάτα «Πού κατεβαίνω;».')));
    showOnMap(LineSel(line, variants: {variant}));
    return;
  }
  await showRide(context, line: line, st: st, vehicle: bus, alight: alight);
}

// [alight]: the stop to get off at, by name (the planner knows it): no picker then.
Future<void> showRide(BuildContext context, {required String line, required LineStatic st, required Vehicle vehicle, String? alight}) async {
  final stops = st.variants[vehicle.variant]?.stops;
  final next = vehicle.nextStopId == null || stops == null ? -1 : stops.indexOf(vehicle.nextStopId!);
  if (stops == null || next < 0) return;
  final d = Deps.of(context);
  final now = d.live.nowS;
  final etas = [for (var k = next; k < stops.length; k++) etaSeconds(st, vehicle, k, now)];
  final from = next + firstAlight(etas); // the stop it is at is too late to get off at
  if (from >= stops.length) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Το λεωφορείο είναι στο τέρμα: καμία στάση μετά.')));
    return;
  }
  final t = context.tones;
  final known = alight == null ? -1 : stops.indexWhere((id) => fold(st.stops[id]?.name ?? '') == fold(alight));
  final k = known >= from ? known : await showModalBottomSheet<int>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (c) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: .7,
      maxChildSize: .92,
      builder: (c, scroll) => ListView(controller: scroll, padding: const EdgeInsets.fromLTRB(16, 0, 16, 16), children: [
        Row(children: [
          LineBadge(line),
          const SizedBox(width: 12),
          const Expanded(child: Text('Πού κατεβαίνεις;', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600))),
        ]),
        const SizedBox(height: 4),
        Text('Θα δονηθεί το κινητό μία στάση πριν: «Κατέβα στην επόμενη».', style: TextStyle(fontSize: 13, color: t.muted)),
        const SizedBox(height: 8),
        for (var k = from; k < stops.length; k++)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Text('${k - next + 1}', style: TextStyle(fontSize: 13, color: t.muted, fontFeatures: const [FontFeature.tabularFigures()])),
            minLeadingWidth: 24,
            title: Text(titleCase(st.stops[stops[k]]?.name ?? stops[k])),
            trailing: Text(switch (etaSeconds(st, vehicle, k, now)) { final e? => '${mins(e)} · ${clockIn(e)}', null => '' }),
            onTap: () => Navigator.pop(c, k),
          ),
      ]),
    ),
  );
  if (k == null || !context.mounted) return;
  final ok = await AlertService.ensurePermissions(context, weekly: false);
  if (!context.mounted) return;
  final nowUtc = DateTime.now().toUtc();
  final name = st.stops[stops[k]]?.name ?? '';
  d.store.putRule(Rule(
    id: 'ride${nowUtc.microsecondsSinceEpoch}',
    line: line,
    variant: vehicle.variant!,
    stopIndex: k,
    stopId: stops[k],
    stopName: name,
    mode: AlertMode.stops,
    n: 1,
    days: 0,
    startMin: 0,
    endMin: 0,
    untilS: nowUtc.millisecondsSinceEpoch ~/ 1000 + 3 * 3600,
    live: true,
    kind: RuleKind.ride,
    vehicle: vehicle.id,
  ));
  await AlertService.sync(d.store);
  if (!context.mounted) return;
  final eta = etaSeconds(st, vehicle, k, d.live.nowS);
  final left = k - next + 1;
  await showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (c) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            LineBadge(line),
            const SizedBox(width: 12),
            Expanded(child: Text(ok ? 'Είσαι μέσα · σε παρακολουθώ' : 'Χωρίς άδεια ειδοποιήσεων', style: TextStyle(fontSize: 14, color: c.tones.muted))),
          ]),
          const SizedBox(height: 14),
          Text('Κατεβαίνεις στο', style: TextStyle(fontSize: 14, color: c.tones.muted)),
          Text(titleCase(name), style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w700, height: 1.1)),
          const SizedBox(height: 4),
          Text.rich(TextSpan(children: [
            TextSpan(text: '$left ${left == 1 ? 'στάση' : 'στάσεις'}', style: const TextStyle(fontWeight: FontWeight.w700)),
            if (eta != null) TextSpan(text: ' · περίπου ${mins(eta)} · ${clockIn(eta)}'),
          ]), style: const TextStyle(fontSize: 15)),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: c.tones.surface, borderRadius: BorderRadius.circular(16)),
            child: const Row(children: [
              Icon(Icons.vibration),
              SizedBox(width: 12),
              Expanded(child: Text('Θα δονηθεί το κινητό μία στάση πριν: «Κατέβα στην επόμενη». Το βλέπεις και στις Ειδοποιήσεις.', style: TextStyle(fontSize: 14, height: 1.35))),
            ]),
          ),
          const SizedBox(height: 12),
          SizedBox(width: double.infinity, height: 48, child: FilledButton(onPressed: () => Navigator.pop(c), child: const Text('Εντάξει'))),
        ]),
      ),
    ),
  );
}
