// Screen 7 · Ειδοποίησέ με: minutes or stops before the bus reaches the user's stop, with what that
// means right now. Creates a one-off rule (or a weekly one) that the background service watches.

import 'package:flutter/material.dart';

import '../background/service.dart';
import '../core/athens_time.dart';
import '../core/eta.dart';
import '../core/models.dart';
import '../core/rules.dart';
import '../data/live.dart';
import 'stop_screen.dart';
import 'theme.dart';
import 'widgets.dart';

const oneOffS = 90 * 60; // a one-off alert watches for 90 minutes

Future<void> showAlertSheet(BuildContext context, {required StopRef stop, required Arrival arrival}) async {
  final d = Deps.of(context);
  final st = d.live.statics[arrival.line] ?? await d.api.lineStatic(arrival.line);
  final variant = st.variants[arrival.variant];
  if (variant == null || !context.mounted) return;
  final ids = stopIdsNear(st, stop.name, stop.lat, stop.lon).toSet();
  final i = variant.stops.indexWhere(ids.contains);
  if (i < 0) return;
  await showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (_) => AlertSheet(stop: stop, line: arrival.line, variantId: arrival.variant, st: st, stopIndex: i),
  );
}

class AlertSheet extends StatefulWidget {
  const AlertSheet({super.key, required this.stop, required this.line, required this.variantId, required this.st, required this.stopIndex});
  final StopRef stop;
  final String line, variantId;
  final LineStatic st;
  final int stopIndex;

  @override
  State<AlertSheet> createState() => _AlertSheetState();
}

class _AlertSheetState extends State<AlertSheet> {
  AlertMode mode = AlertMode.minutes;
  int n = 5;
  late bool live = Deps.of(context).store.liveDefault;

  Variant get v => widget.st.variants[widget.variantId]!;

  // Where the bus is when the alert fires: n stops back, or the stop about n minutes back at the
  // typical speed when no live data says otherwise.
  (String, int)? get meaning {
    final i = widget.stopIndex;
    if (mode == AlertMode.stops) {
      final k = i - n;
      return k < 0 ? null : (widget.st.stops[v.stops[k]]?.name ?? '', n);
    }
    final offs = widget.st.offsetsFor(widget.variantId);
    final back = n * 60 * 4.2;
    for (var k = i - 1; k >= 0; k--) {
      if (offs[i] - offs[k] >= back) return (widget.st.stops[v.stops[k]]?.name ?? '', i - k);
    }
    return null;
  }

  Rule _rule({required bool weekly}) {
    final now = DateTime.now().toUtc();
    final wall = athensWall(now);
    final m = wall.hour * 60 + wall.minute;
    final start = ((m - 10) ~/ 5 * 5).clamp(0, 1380);
    return Rule(
      id: '${now.microsecondsSinceEpoch}',
      line: widget.line,
      variant: widget.variantId,
      stopIndex: widget.stopIndex,
      stopId: v.stops[widget.stopIndex],
      stopName: widget.stop.name,
      mode: mode,
      n: n,
      days: weekly ? 0x1F : 0,
      startMin: start,
      endMin: (start + 45).clamp(0, 1440),
      untilS: weekly ? null : now.millisecondsSinceEpoch ~/ 1000 + oneOffS,
      live: live,
    );
  }

  Future<void> _create({required bool weekly}) async {
    final d = Deps.of(context);
    final ok = await AlertService.ensurePermissions(context, weekly: weekly);
    final exact = !weekly || await AlertService.exactAllowed();
    if (!mounted) return;
    d.store.putRule(_rule(weekly: weekly));
    await AlertService.sync(d.store);
    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(ok
          ? (weekly ? 'Κανόνας: Δε–Πα τέτοια ώρα.${exact ? '' : ' Χωρίς άδεια για ακριβή ξυπνητήρια μπορεί να ξεκινά λίγα λεπτά αργότερα.'}' : 'Θα σε ειδοποιήσω για το ${widget.line}.')
          : 'Χωρίς άδεια ειδοποιήσεων δεν μπορώ να σε ειδοποιήσω.'),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tones;
    final mean = meaning;
    final unit = mode == AlertMode.minutes ? '′' : '';
    final under = mode == AlertMode.minutes ? 'πριν φτάσει' : (n == 1 ? 'στάση πριν' : 'στάσεις πριν');
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, 20 + MediaQuery.of(context).viewInsets.bottom + MediaQuery.paddingOf(context).bottom),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          LineBadge(widget.line),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Ειδοποίησέ με στο ${titleCase(widget.stop.name)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              Text('προς ${titleCase(v.headsign)}', style: TextStyle(fontSize: 13, color: t.muted)),
            ]),
          ),
        ]),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: SegmentedButton<AlertMode>(
            segments: const [
              ButtonSegment(value: AlertMode.minutes, label: Text('Λεπτά πριν')),
              ButtonSegment(value: AlertMode.stops, label: Text('Στάσεις πριν')),
            ],
            selected: {mode},
            onSelectionChanged: (s) => setState(() {
              mode = s.first;
              n = mode == AlertMode.minutes ? 5 : 3;
            }),
          ),
        ),
        const SizedBox(height: 16),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          IconButton.filledTonal(tooltip: 'Λιγότερο', onPressed: n > 1 ? () => setState(() => n--) : null, icon: const Icon(Icons.remove)),
          const SizedBox(width: 24),
          SizedBox(
            width: 140,
            child: Column(children: [
              Text('$n$unit', style: const TextStyle(fontSize: 52, fontWeight: FontWeight.w700, height: 1, fontFeatures: [FontFeature.tabularFigures()])),
              Text(under, style: TextStyle(fontSize: 14, color: t.muted)),
            ]),
          ),
          const SizedBox(width: 24),
          IconButton.filledTonal(
              tooltip: 'Περισσότερο', onPressed: n < (mode == AlertMode.minutes ? 30 : 10) ? () => setState(() => n++) : null, icon: const Icon(Icons.add)),
        ]),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: t.surface, borderRadius: BorderRadius.circular(14)),
          child: mean == null
              ? const Text('Η στάση σου είναι κοντά στην αφετηρία: θα σε ειδοποιήσω μόλις ξεκινήσει.', style: TextStyle(fontSize: 14, height: 1.35))
              : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Τώρα αυτό σημαίνει', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: t.muted)),
                  const SizedBox(height: 6),
                  Row(children: [
                    StopsDots(mean.$2, color: lineColor(Deps.of(context).store, widget.line).bg),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text.rich(TextSpan(children: [
                        const TextSpan(text: 'όταν είναι στο '),
                        TextSpan(text: titleCase(mean.$1), style: const TextStyle(fontWeight: FontWeight.w700)),
                        TextSpan(text: ', ${mean.$2} ${mean.$2 == 1 ? 'στάση' : 'στάσεις'} πριν'),
                      ])),
                    ),
                  ]),
                  const SizedBox(height: 6),
                  Text('Ο χρόνος διορθώνεται με κάθε στίγμα GPS.', style: TextStyle(fontSize: 13, color: t.muted)),
                ]),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Live στην οθόνη κλειδώματος'),
          subtitle: const Text('Δείχνει την πορεία ως τη στάση σου'),
          value: live,
          onChanged: (x) => setState(() => live = x),
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.repeat),
          title: const Text('Κάθε καθημερινή τέτοια ώρα;', style: TextStyle(fontWeight: FontWeight.w600)),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _create(weekly: true),
        ),
        const SizedBox(height: 4),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: FilledButton(
            onPressed: () => _create(weekly: false),
            child: Text(mode == AlertMode.minutes ? 'Ειδοποίησέ με $n′ πριν' : 'Ειδοποίησέ με $n ${n == 1 ? 'στάση' : 'στάσεις'} πριν',
                style: const TextStyle(fontSize: 16)),
          ),
        ),
      ]),
    );
  }
}
