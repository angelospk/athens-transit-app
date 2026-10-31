// A planned trip step by step (screen 28): walk to the stop, which bus and where to get off, the
// change, the metro, the walk to the end. Leaving now, each bus step shows the next bus live that
// there is time to reach, the first one also «φύγε σε N′»; «Φύγε εγκαίρως», «Πού κατεβαίνω;» and
// «Ακολούθησέ με» follow the trip from there. A step opens its stop or station on the map.

import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../core/eta.dart' show Arrival;
import '../core/leave.dart';
import '../core/models.dart';
import '../core/nearby.dart';
import '../core/route_steps.dart';
import '../core/trip.dart' show MetroStation;
import '../data/live.dart' show nextArrivalsAt;
import 'alert_sheet.dart';
import 'follow.dart';
import 'map_sel.dart';
import 'ride.dart';
import 'stop_screen.dart';
import 'theme.dart';
import 'widgets.dart';

void openRoute(BuildContext context,
        {required TripIndex ix,
        required List<RouteStep> steps,
        required PlanEnd from,
        required PlanEnd to,
        required bool live,
        List<MetroStation> stations = const []}) =>
    Navigator.of(context).push(MaterialPageRoute<void>(
      settings: const RouteSettings(name: 'Διαδρομή'),
      builder: (_) => RouteScreen(ix: ix, steps: steps, from: from, to: to, live: live, stations: stations),
    ));

class RouteScreen extends StatelessWidget {
  const RouteScreen({
    super.key,
    required this.ix,
    required this.steps,
    required this.from,
    required this.to,
    required this.live,
    this.stations = const [],
  });
  final TripIndex ix;
  final List<RouteStep> steps;
  final PlanEnd from, to;
  final bool live; // leaving now: the buses are live
  final List<MetroStation> stations;

  // The map with the step's stop or station open; back from there reopens the planner and this trip.
  void _show(BuildContext context, RouteStep s) {
    final at = s.fromAt ?? s.toAt;
    final name = s.fromAt != null ? s.from : s.to;
    if (at == null) return;
    if (s.kind == StepKind.metro) {
      final st = stations.where((x) => x.name == name).firstOrNull;
      showOnMap(StationSel(name, at, lines: st?.lines ?? const []));
    } else {
      showOnMap(StopSel(StopRef(name: name, lat: at.$1, lon: at.$2, lines: linesAt(ix, name, at.$1, at.$2))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tones;
    final total = totalMinutes(steps);
    final firstBus = steps.indexWhere((s) => s.kind == StepKind.bus);
    var before = 0; // minutes from now to the start of each step
    final tiles = <Widget>[];
    for (var k = 0; k < steps.length; k++) {
      final s = steps[k];
      tiles.add(_StepTile(
        ix: ix,
        step: s,
        last: k == steps.length - 1,
        live: live,
        reachMin: before, // at the stop: the wait for this bus starts there
        first: k == firstBus,
        toStation: k + 1 < steps.length && steps[k + 1].kind == StepKind.metro,
        onMap: () => _show(context, s),
      ));
      before += s.min + s.wait;
    }
    final arrive = DateTime.now().add(Duration(minutes: total));
    final bus = firstBus < 0 ? null : steps[firstBus];
    return Scaffold(
      appBar: AppBar(title: Text('${titleCase(from.label)} → ${titleCase(to.label)}', maxLines: 2, style: const TextStyle(fontSize: 17))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
        children: [
          Row(children: [
            Text('~$total′', style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w700)),
            const SizedBox(width: 12),
            if (live)
              Text('φτάνεις ~${arrive.hour}:${arrive.minute.toString().padLeft(2, '0')}', style: TextStyle(fontSize: 15, color: t.muted)),
          ]),
          Text(
            bus == null
                ? 'Εκτίμηση με αναμονή ~$metroWaitMin′ για το τρένο.'
                : live
                    ? 'Εκτίμηση χωρίς την αναμονή του πρώτου λεωφορείου· η αναμονή φαίνεται live στο βήμα του.'
                    : 'Για αργότερα: εκτίμηση χωρίς αναμονή.',
            style: TextStyle(fontSize: 12, color: t.muted),
          ),
          const SizedBox(height: 12),
          ...tiles,
          if (live && bus != null) ...[
            const SizedBox(height: 16),
            FollowButton(steps: steps, bus: bus),
          ],
        ],
      ),
    );
  }
}

class _StepTile extends StatelessWidget {
  const _StepTile({
    required this.ix,
    required this.step,
    required this.last,
    required this.live,
    required this.reachMin,
    required this.first,
    required this.toStation,
    required this.onMap,
  });
  final TripIndex ix;
  final RouteStep step;
  final bool last, live, first;
  final bool toStation; // the walk ends at a metro or tram station
  final int reachMin;
  final VoidCallback onMap;

  @override
  Widget build(BuildContext context) {
    final t = context.tones;
    final s = step;
    final Widget mark = switch (s.kind) {
      StepKind.walk => Icon(Icons.directions_walk, color: t.muted),
      StepKind.bus => LineBadge(s.line!),
      StepKind.metro => Icon(s.line!.startsWith('T') ? Icons.tram_outlined : Icons.subway_outlined),
    };
    final String title;
    final List<String> lines;
    switch (s.kind) {
      case StepKind.walk:
        title = s.to.isEmpty ? 'Περπάτα ως τον προορισμό' : (s.from.isEmpty ? 'Περπάτα ως ${toStation ? 'τον σταθμό' : 'τη στάση'} ${titleCase(s.to)}' : 'Περπάτα ως ${titleCase(s.to)}');
        lines = [];
      case StepKind.bus:
        title = 'Ανέβα στο ${s.line}${s.toward == null ? '' : ' προς ${titleCase(s.toward!)}'}';
        lines = [
          'Στάση: ${titleCase(s.from)}',
          'Κατέβα: ${titleCase(s.to)} · ${s.stops} ${s.stops == 1 ? 'στάση' : 'στάσεις'}',
          if (s.wait > 0) 'Αλλαγή: αναμονή ~${s.wait}′',
        ];
      case StepKind.metro:
        title = '${s.line!.startsWith('T') ? 'Τραμ' : 'Μετρό'} ${s.line}: ${titleCase(s.from)} → ${titleCase(s.to)}';
        lines = ['Τρένο κάθε λίγα λεπτά (πρόγραμμα, όχι live), αναμονή ~${s.wait}′'];
    }
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 44,
            child: Column(children: [
              const SizedBox(height: 10),
              mark,
              if (!last) Expanded(child: Center(child: Container(width: 2, color: t.rule))),
            ]),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: s.fromAt == null && s.toAt == null ? null : onMap,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(4, 10, 4, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Expanded(child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600))),
                      Text('${s.min}′', style: TextStyle(fontSize: 15, color: t.muted)),
                    ]),
                    for (final l in lines) Text(l, style: TextStyle(fontSize: 14, color: t.muted)),
                    // A later bus waits on the first one's live wait: no claim which one you catch.
                    if (s.kind == StepKind.bus && live && first) _NextBus(ix: ix, step: s, reachMin: reachMin, first: first),
                    if (s.kind == StepKind.bus && live && !first)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          icon: const Icon(Icons.flag_outlined, size: 18),
                          label: const Text('Πού κατεβαίνω;'),
                          onPressed: () => rideFromHere(context, line: s.line!, variant: s.variant!, alight: s.to),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// The next bus of the step's direction that there is time to reach the stop for, live, every 30 s.
class _NextBus extends StatefulWidget {
  const _NextBus({required this.ix, required this.step, required this.reachMin, required this.first});
  final TripIndex ix;
  final RouteStep step;
  final int reachMin; // minutes until the user is at the stop
  final bool first; // the first bus: «φύγε σε N′» and «Φύγε εγκαίρως»

  @override
  State<_NextBus> createState() => _NextBusState();
}

class _NextBusState extends State<_NextBus> {
  List<Arrival> _arrivals = [];
  int _at = 0;
  bool _asked = false;
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

  (String, double, double) get _stop => (widget.step.from, widget.step.fromAt!.$1, widget.step.fromAt!.$2);

  Future<void> _load() async {
    final live = Deps.of(context).live;
    try {
      final got = await nextArrivalsAt(live, widget.step.line!, widget.step.variant!, _stop);
      if (mounted) {
        setState(() {
          _arrivals = got;
          _at = live.nowS;
          _asked = true;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _asked = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tones;
    final s = widget.step;
    final age = _arrivals.isEmpty ? 0 : max(0, Deps.of(context).live.nowS - _at);
    final next = _arrivals.map((a) => (a: a, eta: a.etaS - age)).where((x) => x.eta >= widget.reachMin * 60).firstOrNull;
    final leave = next == null || !widget.first ? null : leaveInMinutes(next.eta, widget.reachMin, 1);
    final (name, lat, lon) = _stop;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 6),
        if (next == null)
          Text(
            _asked ? (_arrivals.isEmpty ? 'Κανένα λεωφορείο με GPS κοντά τώρα' : 'Δεν προλαβαίνεις αυτά που έρχονται τώρα') : 'Ψάχνω το επόμενο…',
            style: TextStyle(fontSize: 13, color: t.muted),
          )
        else
          Row(children: [
            Dot(delayNote(context, next.a.delayS)?.$2 ?? t.onTime),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                'Το επόμενο που προλαβαίνεις σε ${mins(next.eta)} (${clockIn(next.eta)})${leave == null ? '' : leave <= 0 ? ' · φύγε τώρα' : ' · φύγε σε $leave′'}',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: leave != null && leave <= 0 ? t.late : null),
              ),
            ),
          ]),
        Wrap(spacing: 4, children: [
          if (widget.first && next != null)
            TextButton.icon(
              icon: const Icon(Icons.notifications_active_outlined, size: 18),
              label: const Text('Φύγε εγκαίρως'),
              onPressed: () => showAlertSheet(
                context,
                stop: StopRef(name: name, lat: lat, lon: lon, lines: linesAt(widget.ix, name, lat, lon)),
                arrival: next.a,
                leave: true,
              ),
            ),
          TextButton.icon(
            icon: const Icon(Icons.flag_outlined, size: 18),
            label: const Text('Πού κατεβαίνω;'),
            onPressed: () => rideFromHere(context, line: s.line!, variant: s.variant!, alight: s.to),
          ),
        ]),
      ],
    );
  }
}
