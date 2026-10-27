// Screen 10 · Κανόνας ως πρόταση: "Κάθε Δε–Πα από 08:00 ως 08:40, πες μου 5′ πριν φτάσει το 602 στην
// 5η Καλογρέζας." Each underlined word opens its choice.

import 'package:flutter/material.dart';

import '../background/service.dart';
import '../core/models.dart';
import '../core/rules.dart';
import '../data/live.dart';
import '../data/store.dart';
import 'rules_screen.dart';
import 'theme.dart';
import 'widgets.dart';

enum When { minutes, stops, leave }

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
  late When when = widget.rule?.mode == AlertMode.stops ? When.stops : When.minutes;
  late int n = widget.rule?.n ?? 5;
  late bool live = widget.rule?.live ?? true;
  FavStop? fav;
  String? line;
  // variant id → (stop index, headsign) for the chosen line at the chosen stop
  Map<String, (int, String, String)> variants = {};
  String? variant;

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
    if (mounted) {
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
    );
    d.store.putRule(r);
    await AlertService.sync(d.store);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tones;
    final store = Deps.of(context).store;
    final word = TextStyle(fontWeight: FontWeight.w700, decoration: TextDecoration.underline, decorationColor: t.muted, color: t.ink);
    Widget w(String s, VoidCallback onTap) => InkWell(onTap: onTap, child: Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Text(s, style: word)));
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
              w(daysText(days), _days),
              const Text('από'),
              w(hm(start), () => _time(true)),
              const Text('ως'),
              w('${hm(end)},', () => _time(false)),
              const Text('πες μου'),
              w(whenWord, _when),
              const Text('για το'),
              w(line ?? '—', _line),
              const Text('στο'),
              w('${titleCase(fav?.name ?? '—')}.', _stop),
            ]),
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
      ]),
    );
  }

  Future<void> _days() async {
    var sel = days;
    final r = await showModalBottomSheet<int>(
      context: context,
      showDragHandle: true,
      builder: (c) => StatefulBuilder(
        builder: (c, set) => Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Wrap(spacing: 8, children: [
              for (var i = 0; i < 7; i++)
                FilterChip(label: Text(dayNames[i]), selected: sel & (1 << i) != 0, onSelected: (_) => set(() => sel ^= 1 << i)),
            ]),
            const SizedBox(height: 16),
            FilledButton(onPressed: sel == 0 ? null : () => Navigator.pop(c, sel), child: const Text('Εντάξει')),
          ]),
        ),
      ),
    );
    if (r != null) setState(() => days = r);
  }

  Future<void> _time(bool isStart) async {
    final m = isStart ? start : end;
    final r = await showTimePicker(context: context, initialTime: TimeOfDay(hour: m ~/ 60, minute: m % 60));
    if (r == null) return;
    setState(() => isStart ? start = r.hour * 60 + r.minute : end = r.hour * 60 + r.minute);
  }

  Future<void> _when() async {
    final r = await showModalBottomSheet<(When, int)>(
      context: context,
      showDragHandle: true,
      builder: (c) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          for (final m in [3, 5, 10]) ListTile(title: Text('$m′ πριν φτάσει'), onTap: () => Navigator.pop(c, (When.minutes, m))),
          for (final s in [2, 3, 5]) ListTile(title: Text('$s στάσεις πριν φτάσει'), onTap: () => Navigator.pop(c, (When.stops, s))),
          ListTile(title: const Text('πότε να φύγω (περπάτημα + 5′)'), onTap: () => Navigator.pop(c, (When.leave, 0))),
        ]),
      ),
    );
    if (r == null) return;
    setState(() {
      when = r.$1;
      if (r.$1 != When.leave) n = r.$2;
    });
  }

  Future<void> _line() async {
    final f = fav;
    if (f == null) return;
    final r = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (c) => SafeArea(
        child: Wrap(spacing: 8, runSpacing: 8, children: [
          for (final l in f.lines) ActionChip(label: Text(l), onPressed: () => Navigator.pop(c, l)),
        ]),
      ),
    );
    if (r == null) return;
    setState(() => line = r);
    await _loadVariants();
  }

  Future<void> _stop() async {
    final store = Deps.of(context).store;
    final r = await showModalBottomSheet<FavStop>(
      context: context,
      showDragHandle: true,
      builder: (c) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          for (final f in store.favs) ListTile(title: Text(titleCase(f.name)), subtitle: Text(f.lines.join(', ')), onTap: () => Navigator.pop(c, f)),
        ]),
      ),
    );
    if (r != null) await _pickStop(r);
  }
}
