// Screen 7 · Ειδοποίησέ με: minutes or stops before the bus reaches the user's stop, with what that
// means right now; or (screen 16) "Πες μου πότε να φύγω": the walk from where the user is, and a few
// minutes at the stop before the bus. Creates a one-off rule (or a weekly one) that the background
// service watches.

import 'package:flutter/material.dart';

import '../background/service.dart';
import '../core/athens_time.dart';
import '../core/eta.dart';
import '../core/geo.dart';
import '../core/last_bus.dart';
import '../core/leave.dart';
import '../core/models.dart';
import '../core/rules.dart';
import '../data/live.dart';
import '../data/locate.dart';
import 'stop_screen.dart';
import 'theme.dart';
import 'widgets.dart';

const oneOffS = 90 * 60; // a one-off alert watches for 90 minutes
const lateAlertMin = 5; // "Πες μου και αν αργεί": a delay of this many minutes

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
    builder: (_) => AlertSheet(stop: stop, line: arrival.line, variantId: arrival.variant, st: st, stopIndex: i, etaS: arrival.etaS),
  );
}

/// "HH:MM" of [s] seconds after an Athens midnight (past 24:00 too).
String dayClock(int s) => '${(s ~/ 3600 % 24).toString().padLeft(2, '0')}:${(s % 3600 ~/ 60).toString().padLeft(2, '0')}';

/// «Ειδοποίησέ με για το τελευταίο» (screen 24): a notification [beforeMin] minutes before the last run
/// of today's timetable passes stop [i] of [variantId]. Returns what to tell the user.
Future<String> remindLast(BuildContext context,
    {required String line, required LineStatic st, required String variantId, required int i, required String stopName, int beforeMin = 15}) async {
  final d = Deps.of(context);
  final now = DateTime.now().toUtc();
  try {
    final sched = await d.api.lineSchedule(line);
    final r = sched == null ? null : lastRun(sched, st, variantId, i);
    if (r == null) return 'Δεν βρήκα πρόγραμμα για το $line.';
    final at = athensDayUtc(now, r.atStopS);
    if (at.isBefore(now)) return 'Το τελευταίο $line πέρασε ήδη (~${dayClock(r.atStopS)}).';
    if (!context.mounted || !await AlertService.ensurePermissions(context)) {
      return 'Χωρίς άδεια ειδοποιήσεων δεν μπορώ να σε ειδοποιήσω.';
    }
    var fire = at.subtract(Duration(minutes: beforeMin));
    if (fire.isBefore(now)) fire = now.add(const Duration(seconds: 5));
    await AlertService.noteAt(
      fire,
      'Σε λίγο περνά το τελευταίο $line',
      'Από ${titleCase(stopName)} ~${dayClock(r.atStopS)} (φεύγει ${gtfsClock(r.t)} από την αφετηρία).',
    );
    return 'Θα σε ειδοποιήσω $beforeMin′ πριν: το τελευταίο $line περνά ~${dayClock(r.atStopS)}.';
  } catch (_) {
    return 'Δεν φόρτωσε το πρόγραμμα. Δοκίμασε ξανά με σύνδεση.';
  }
}

class AlertSheet extends StatefulWidget {
  const AlertSheet({super.key, required this.stop, required this.line, required this.variantId, required this.st, required this.stopIndex, this.etaS});
  final StopRef stop;
  final String line, variantId;
  final LineStatic st;
  final int stopIndex;
  final int? etaS; // the bus it was opened from: for "when to leave" now

  @override
  State<AlertSheet> createState() => _AlertSheetState();
}

class _AlertSheetState extends State<AlertSheet> {
  AlertMode mode = AlertMode.minutes;
  int n = 5;
  bool leave = false; // "Πες μου πότε να φύγω"
  int margin = 3; // minutes at the stop before the bus
  int? walk; // minutes on foot from the user's position; null until asked
  bool locating = false;
  bool late = false; // "Πες μου και αν αργεί"

  // The user's position, asked only when "when to leave" is picked; the sheet says why first.
  Future<void> _locate() async {
    setState(() => locating = true);
    final p = await myPosition();
    if (!mounted) return;
    setState(() {
      locating = false;
      walk = p == null ? null : walkMinutes(distM(p, (widget.stop.lat, widget.stop.lon)));
    });
    if (p == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Δεν βρέθηκε η θέση σου (άδεια ή GPS). Βάλε τον χρόνο περπατήματος με το χέρι.')));
      setState(() => walk = Deps.of(context).store.walkMin.clamp(1, 60));
    }
  }
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
      mode: leave ? AlertMode.minutes : mode,
      n: leave ? (walk ?? 0) + margin : n,
      kind: leave ? RuleKind.leave : RuleKind.arrive,
      days: weekly ? 0x1F : 0,
      startMin: start,
      endMin: (start + 45).clamp(0, 1440),
      untilS: weekly ? null : now.millisecondsSinceEpoch ~/ 1000 + oneOffS,
      live: live,
      lateMin: late ? lateAlertMin : null,
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
          ? (weekly
              ? 'Κανόνας: Δε–Πα τέτοια ώρα.${exact ? '' : ' Χωρίς άδεια για ακριβή ξυπνητήρια μπορεί να ξεκινά λίγα λεπτά αργότερα.'}'
              : leave
                  ? 'Θα σου πω πότε να φύγεις για το ${widget.line}.'
                  : 'Θα σε ειδοποιήσω για το ${widget.line}.')
          : 'Χωρίς άδεια ειδοποιήσεων δεν μπορώ να σε ειδοποιήσω.'),
    ));
  }

  Future<void> _last() async {
    final messenger = ScaffoldMessenger.of(context);
    final nav = Navigator.of(context);
    final msg = await remindLast(context, line: widget.line, st: widget.st, variantId: widget.variantId, i: widget.stopIndex, stopName: widget.stop.name);
    if (mounted) nav.pop();
    messenger.showSnackBar(SnackBar(content: Text(msg)));
  }

  // Screen 16: "Φύγε σε N′", the bar now / walk / wait, and how early to be at the stop.
  List<Widget> _leave(Tones t) {
    final w = walk;
    if (w == null) {
      return [
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: t.surface, borderRadius: BorderRadius.circular(14)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Χρειάζομαι τη θέση σου', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text('Για να υπολογίσω πόσο περπατάς ως τη στάση και να σου πω πότε να ξεκινήσεις, ώστε να είσαι εκεί έγκαιρα. Η θέση μένει στο κινητό.',
                style: TextStyle(fontSize: 13.5, height: 1.35, color: t.muted)),
            const SizedBox(height: 10),
            FilledButton.tonalIcon(
              onPressed: locating ? null : _locate,
              icon: const Icon(Icons.my_location),
              label: Text(locating ? 'Ψάχνω…' : 'Χρήση της θέσης μου'),
            ),
          ]),
        ),
        const SizedBox(height: 8),
      ];
    }
    final eta = widget.etaS;
    final inMin = eta == null ? null : leaveInMinutes(eta, w, margin);
    final wait = eta == null ? null : (eta / 60).floor() - w - (inMin ?? 0).clamp(0, 999);
    return [
      const SizedBox(height: 16),
      if (inMin != null)
        Text(inMin <= 0 ? 'Φύγε τώρα' : 'Φύγε σε $inMin′', style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w700, height: 1.05)),
      Text(
        [
          if (inMin != null && inMin > 0) 'στις ${clockIn(inMin * 60)}',
          'περπάτημα $w′ ως ${titleCase(widget.stop.name)}',
          if (inMin != null && inMin < 0) 'μάλλον δεν προλαβαίνεις αυτό',
        ].join(' · '),
        style: TextStyle(fontSize: 14, color: inMin != null && inMin < 0 ? t.late : t.muted),
      ),
      if (inMin != null) ...[
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            height: 36,
            child: Row(children: [
              if (inMin > 0) Expanded(flex: inMin, child: _bar(t.surface, t.ink, 'τώρα · $inMin′')),
              Expanded(flex: w, child: _bar(t.indicator, t.ink, 'περπάτημα $w′')),
              if ((wait ?? 0) > 0) Expanded(flex: wait!, child: _bar(lineColor(Deps.of(context).store, widget.line).bg, lineColor(Deps.of(context).store, widget.line).fg, 'περιμένεις $wait′')),
            ]),
          ),
        ),
      ],
      const SizedBox(height: 14),
      Text('Θέλω να είμαι στη στάση', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: t.muted)),
      const SizedBox(height: 6),
      Row(children: [
        for (final m in const [1, 3, 5, 10])
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: ChoiceChip(label: Center(child: Text('$m′ πριν')), selected: margin == m, onSelected: (_) => setState(() => margin = m)),
            ),
          ),
      ]),
      Row(children: [
        Text('Περπάτημα', style: TextStyle(fontSize: 13, color: t.muted)),
        IconButton(tooltip: 'Λιγότερο', onPressed: w > 1 ? () => setState(() => walk = w - 1) : null, icon: const Icon(Icons.remove)),
        Text('$w′', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        IconButton(tooltip: 'Περισσότερο', onPressed: w < 60 ? () => setState(() => walk = w + 1) : null, icon: const Icon(Icons.add)),
      ]),
      Text('Αν το λεωφορείο αργήσει, σου λέω να φύγεις αργότερα: ο χρόνος διορθώνεται με κάθε στίγμα GPS.', style: TextStyle(fontSize: 13, color: t.muted)),
    ];
  }

  Widget _bar(Color bg, Color fg, String s) => Container(
        color: bg,
        alignment: Alignment.center,
        child: Text(s, maxLines: 1, overflow: TextOverflow.clip, softWrap: false, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: fg)),
      );

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
          child: SegmentedButton<int>(
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(value: 0, label: Text('Λεπτά πριν')),
              ButtonSegment(value: 1, label: Text('Στάσεις πριν')),
              ButtonSegment(value: 2, label: Text('Φύγε εγκαίρως')),
            ],
            selected: {leave ? 2 : mode.index},
            onSelectionChanged: (s) => setState(() {
              leave = s.first == 2;
              if (leave) return;
              mode = AlertMode.values[s.first];
              n = mode == AlertMode.minutes ? 5 : 3;
            }),
          ),
        ),
        if (leave) ..._leave(t) else ...[
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
        ],
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Live στην οθόνη κλειδώματος'),
          subtitle: const Text('Δείχνει την πορεία ως τη στάση σου'),
          value: live,
          onChanged: (x) => setState(() => live = x),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Πες μου και αν αργεί'),
          subtitle: const Text('Μία ειδοποίηση όταν ένα λεωφορείο για τη στάση σου έχει καθυστέρηση $lateAlertMin′ ή παραπάνω'),
          value: late,
          onChanged: (x) => setState(() => late = x),
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.repeat),
          title: const Text('Κάθε καθημερινή τέτοια ώρα;', style: TextStyle(fontWeight: FontWeight.w600)),
          trailing: const Icon(Icons.chevron_right),
          onTap: leave && walk == null ? null : () => _create(weekly: true),
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.nightlight_outlined),
          title: const Text('Για το τελευταίο της ημέρας', style: TextStyle(fontWeight: FontWeight.w600)),
          subtitle: const Text('Ειδοποίηση 15′ πριν περάσει από εδώ, από το πρόγραμμα'),
          onTap: _last,
        ),
        const SizedBox(height: 4),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: FilledButton(
            onPressed: leave && walk == null ? null : () => _create(weekly: false),
            child: Text(leave ? 'Πες μου πότε να φύγω' : mode == AlertMode.minutes ? 'Ειδοποίησέ με $n′ πριν' : 'Ειδοποίησέ με $n ${n == 1 ? 'στάση' : 'στάσεις'} πριν',
                style: const TextStyle(fontSize: 16)),
          ),
        ),
      ]),
    );
  }
}
