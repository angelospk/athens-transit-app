// Screen 10 · Κανόνας ως πρόταση: "Κάθε Δε–Πα από 08:00 ως 08:40, πες μου 5′ πριν φτάσει το 602 στην
// 5η Καλογρέζας." Each changeable word has a chevron beside it, as in Apple's Shortcuts: a tap turns
// the chevron and opens the word's choices under the sentence.

import 'package:flutter/material.dart';

import '../background/service.dart';
import '../core/models.dart';
import '../core/rules.dart';
import '../data/live.dart';
import '../data/store.dart';
import 'alert_sheet.dart' show lateAlertMin;
import 'rules_screen.dart';
import 'theme.dart';
import 'widgets.dart';

enum When { minutes, stops, leave }

enum _Word { days, start, end, when, line, stop }

class RuleEditScreen extends StatefulWidget {
  const RuleEditScreen({super.key, this.rule});
  final Rule? rule;

  @override
  State<RuleEditScreen> createState() => _RuleEditScreenState();
}

class _RuleEditScreenState extends State<RuleEditScreen> {
  late int days = widget.rule?.days ?? 0x1F;
  late int start = widget.rule?.startMin ?? 8 * 60;
  late int end = widget.rule?.endMin ?? 8 * 60 + 40;
  late When when = switch (widget.rule) {
    final r? when r.kind == RuleKind.leave => When.leave,
    final r? when r.mode == AlertMode.stops => When.stops,
    _ => When.minutes,
  };
  late int n = widget.rule?.n ?? 5;
  late bool live = widget.rule?.live ?? true;
  late bool lateToo = widget.rule?.lateMin != null; // "Πες μου και αν αργεί"
  FavStop? fav;
  String? line;
  // variant id → (stop index, headsign) for the chosen line at the chosen stop
  Map<String, (int, String, String)> variants = {};
  String? variant;
  _Word? open; // the word whose choices show under the sentence

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final r = widget.rule;
    final store = Deps.of(context).store;
    if (r != null && fav == null) {
      fav = store.favs.where((f) => f.name == r.stopName).firstOrNull;
      line = r.line;
      variant = r.variant;
      variants = {r.variant: (r.stopIndex, r.stopId, '')};
    } else if (fav == null && store.favs.isNotEmpty) {
      final f = store.favsByTime(DateTime.now().toUtc()).first;
      _pickStop(f);
    }
  }

  Future<void> _pickStop(FavStop f) async {
    setState(() {
      fav = f;
      line = f.lines.firstOrNull;
    });
    if (line != null) await _loadVariants();
  }

  Future<void> _loadVariants() async {
    final d = Deps.of(context);
    final f = fav, l = line;
    if (f == null || l == null) return;
    setState(() {
      variants = {}; // the old line's direction must not be saved with the new line
      variant = null;
    });
    final LineStatic st;
    try {
      st = await d.api.lineStatic(l);
    } catch (_) {
      return;
    }
    final ids = stopIdsNear(st, f.name, f.lat, f.lon).toSet();
    final out = <String, (int, String, String)>{};
    st.variants.forEach((id, v) {
      final i = v.stops.indexWhere(ids.contains);
      if (i >= 0 && i < v.stops.length - 1) out[id] = (i, v.stops[i], v.headsign); // not the last stop
    });
    if (mounted && fav == f && line == l) {
      setState(() {
        variants = out;
        variant = out.keys.firstOrNull;
      });
    }
  }

  int get effectiveN => when == When.leave ? Deps.of(context).store.walkMin + 5 : n;

  Future<void> _save() async {
    final d = Deps.of(context);
    final v = variant, f = fav, l = line;
    if (v == null || f == null || l == null) return;
    final (i, stopId, _) = variants[v]!;
    await AlertService.ensurePermissions(context, weekly: true);
    final r = Rule(
      id: widget.rule?.id ?? '${DateTime.now().microsecondsSinceEpoch}',
      line: l,
      variant: v,
      stopIndex: i,
      stopId: stopId,
      stopName: f.name,
      mode: when == When.stops ? AlertMode.stops : AlertMode.minutes,
      n: effectiveN,
      days: days,
      startMin: start,
      endMin: end,
      live: live,
      enabled: widget.rule?.enabled ?? true,
      pausedUntilS: widget.rule?.pausedUntilS,
      kind: when == When.leave ? RuleKind.leave : RuleKind.arrive,
      lateMin: lateToo ? (widget.rule?.lateMin ?? lateAlertMin) : null,
    );
    d.store.putRule(r);
    await AlertService.sync(d.store);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tones;
    final store = Deps.of(context).store;
    final accent = Theme.of(context).colorScheme.primary;
    Widget w(_Word k, String text) {
      final on = open == k;
      return InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => setState(() => open = on ? null : k),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Text(text, style: TextStyle(fontWeight: FontWeight.w700, color: accent)),
            AnimatedRotation(
              turns: on ? .5 : 0,
              duration: const Duration(milliseconds: 180),
              child: Icon(Icons.expand_more, size: 26, color: accent),
            ),
          ]),
        ),
      );
    }

    final whenWord = switch (when) {
      When.minutes => '$n′ πριν φτάσει',
      When.stops => '$n ${n == 1 ? 'στάση' : 'στάσεις'} πριν φτάσει',
      When.leave => 'πότε να φύγω',
    };
    final ready = variant != null && fav != null && line != null && days != 0 && end > start;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Κανόνας'),
        backgroundColor: t.ground,
        surfaceTintColor: Colors.transparent,
        actions: [
          if (widget.rule != null)
            IconButton(
              tooltip: 'Διαγραφή',
              icon: const Icon(Icons.delete_outline),
              onPressed: () async {
                store.removeRule(widget.rule!.id);
                await AlertService.sync(store);
                if (context.mounted) Navigator.pop(context);
              },
            ),
          TextButton(onPressed: ready ? _save : null, child: const Text('Αποθήκευση')),
        ],
      ),
      body: ListView(padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + MediaQuery.paddingOf(context).bottom), children: [
        if (store.favs.isEmpty)
          Text('Πρώτα αποθήκευσε μια στάση (καρτέλα Στάσεις).', style: TextStyle(color: t.muted))
        else
          DefaultTextStyle.merge(
            style: const TextStyle(fontSize: 24, height: 1.5),
            child: Wrap(crossAxisAlignment: WrapCrossAlignment.center, spacing: 6, children: [
              const Text('Κάθε'),
              w(_Word.days, daysText(days)),
              const Text('από'),
              w(_Word.start, hm(start)),
              const Text('ως'),
              w(_Word.end, hm(end)),
              const Text('πες μου'),
              w(_Word.when, whenWord),
              const Text('για το'),
              w(_Word.line, line ?? '—'),
              const Text('στο'),
              w(_Word.stop, titleCase(fav?.name ?? '—')),
            ]),
          ),
        AnimatedSize(
          duration: const Duration(milliseconds: 180),
          alignment: Alignment.topCenter,
          child: open == null
              ? const SizedBox(width: double.infinity)
              : Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(top: 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: t.surface, borderRadius: BorderRadius.circular(20)),
                  child: _choices(open!),
                ),
        ),
        const SizedBox(height: 16),
        if (variants.length > 1)
          Wrap(spacing: 8, children: [
            for (final e in variants.entries)
              ChoiceChip(label: Text('προς ${titleCase(e.value.$3)}'), selected: variant == e.key, onSelected: (_) => setState(() => variant = e.key)),
          ]),
        if (line != null && variants.isEmpty)
          Text('Το $line δεν σταματά σε αυτή τη στάση (ή είναι το τέρμα του).', style: TextStyle(color: t.late)),
        if (when == When.leave)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text('Περπάτημα ${store.walkMin}′ + να είσαι εκεί 5′ νωρίτερα = ειδοποίηση $effectiveN′ πριν φτάσει.', style: TextStyle(color: t.muted)),
          ),
        if (end <= start) Text('Το τέλος πρέπει να είναι μετά την αρχή.', style: TextStyle(color: t.late)),
        const SizedBox(height: 16),
        SwitchListTile(contentPadding: EdgeInsets.zero, title: const Text('Live στην οθόνη κλειδώματος'), value: live, onChanged: (x) => setState(() => live = x)),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Πες μου και αν αργεί'),
          subtitle: const Text('Όταν η καθυστέρηση φτάσει $lateAlertMin′'),
          value: lateToo,
          onChanged: (x) => setState(() => lateToo = x),
        ),
      ]),
    );
  }

  void _setWhen(When w, int v) => setState(() {
        when = w;
        n = v;
      });

  // The choices of one word, under the sentence.
  Widget _choices(_Word k) {
    final store = Deps.of(context).store;
    Widget chip(String label, bool on, VoidCallback tap) => ChoiceChip(label: Text(label), selected: on, onSelected: (_) => tap());
    Widget wrap(List<Widget> c) => Wrap(spacing: 8, runSpacing: 8, children: c);
    switch (k) {
      case _Word.days:
        return wrap([
          for (var i = 0; i < 7; i++)
            FilterChip(
              label: Text(dayNames[i]),
              selected: days & (1 << i) != 0,
              onSelected: (_) => setState(() => days = (days ^ (1 << i)) == 0 ? days : days ^ (1 << i)),
            ),
          chip('Δε–Πα', days == 0x1F, () => setState(() => days = 0x1F)),
          chip('Κάθε μέρα', days == 0x7F, () => setState(() => days = 0x7F)),
        ]);
      case _Word.start || _Word.end:
        final isStart = k == _Word.start;
        final m = isStart ? start : end;
        void set(int v) => setState(() => isStart ? start = v.clamp(0, 24 * 60 - 1) : end = v.clamp(0, 24 * 60 - 1));
        return Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          IconButton.filledTonal(tooltip: '15′ νωρίτερα', onPressed: () => set(m - 15), icon: const Icon(Icons.remove)),
          TextButton(
            onPressed: () async {
              final r = await showTimePicker(context: context, initialTime: TimeOfDay(hour: m ~/ 60, minute: m % 60));
              if (r != null) set(r.hour * 60 + r.minute);
            },
            child: Text(hm(m), style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700, fontFeatures: [FontFeature.tabularFigures()])),
          ),
          IconButton.filledTonal(tooltip: '15′ αργότερα', onPressed: () => set(m + 15), icon: const Icon(Icons.add)),
        ]);
      case _Word.when:
        return wrap([
          for (final m in [3, 5, 10]) chip('$m′ πριν φτάσει', when == When.minutes && n == m, () => _setWhen(When.minutes, m)),
          for (final x in [2, 3, 5]) chip('$x στάσεις πριν', when == When.stops && n == x, () => _setWhen(When.stops, x)),
          chip('πότε να φύγω', when == When.leave, () => setState(() => when = When.leave)),
        ]);
      case _Word.line:
        final f = fav;
        if (f == null) return const Text('Διάλεξε πρώτα στάση.');
        return wrap([
          for (final l in f.lines)
            chip(l, line == l, () async {
              setState(() => line = l);
              await _loadVariants();
            }),
        ]);
      case _Word.stop:
        return wrap([for (final f in store.favs) chip(titleCase(f.name), fav?.key == f.key, () => _pickStop(f))]);
    }
  }
}
