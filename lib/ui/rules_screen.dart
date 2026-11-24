// Screen 9 · Ειδοποιήσεις: what watches now (one-off alerts) and the weekly rules, written as sentences.

import 'package:flutter/material.dart';

import '../background/service.dart';
import '../core/athens_time.dart';
import '../core/rules.dart';
import '../l10n/l10n.dart';
import 'rule_edit.dart';
import 'theme.dart';
import 'widgets.dart';

/// The two-letter weekdays, Monday first.
List<String> get dayNames =>
    [l10n.rulesDayMon, l10n.rulesDayTue, l10n.rulesDayWed, l10n.rulesDayThu, l10n.rulesDayFri, l10n.rulesDaySat, l10n.rulesDaySun];

String daysText(int days) {
  if (days == 0x1F) return l10n.rulesMonFri;
  if (days == 0x7F) return l10n.rulesEveryDay;
  if (days == 0x60) return l10n.rulesWeekend;
  final names = dayNames;
  return [for (var i = 0; i < 7; i++) if (days & (1 << i) != 0) names[i]].join(', ');
}

String hm(int m) => '${(m ~/ 60).toString().padLeft(2, '0')}:${(m % 60).toString().padLeft(2, '0')}';

String whenText(Rule r) =>
    (r.mode == AlertMode.minutes ? l10n.rulesMinutesBefore(r.n) : l10n.rulesStopsBefore(r.n)) + (r.lateMin == null ? '' : ' · ${l10n.rulesAndIfLate}');

class RulesScreen extends StatefulWidget {
  const RulesScreen({super.key});

  @override
  State<RulesScreen> createState() => _RulesScreenState();
}

// Rules stopped from the live card ("Σταμάτα") say so, with a way to run them again today. Read again
// when the app comes back and whenever the rules change.
class _RulesScreenState extends State<RulesScreen> with WidgetsBindingObserver {
  Set<String> stopped = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _check();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState s) {
    if (s == AppLifecycleState.resumed) _check();
  }

  Future<void> _check() async {
    final s = await AlertService.stoppedNow();
    if (mounted && (s.length != stopped.length || !s.containsAll(stopped))) setState(() => stopped = s);
  }

  @override
  Widget build(BuildContext context) {
    final d = Deps.of(context);
    final t = context.tones;
    final s = context.l10n;
    return ListenableBuilder(
      listenable: d.store,
      builder: (context, _) {
        _check();
        final now = DateTime.now().toUtc();
        final nowS = now.millisecondsSinceEpoch ~/ 1000;
        final oneOff = d.store.rules.where((r) => r.untilS != null && r.untilS! > nowS).toList();
        final weekly = d.store.rules.where((r) => r.untilS == null).toList();
        Widget head(String s) => Padding(
              padding: const EdgeInsets.fromLTRB(8, 20, 8, 8),
              child: Text(s, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: t.muted)),
            );
        return Scaffold(
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RuleEditScreen())),
            icon: const Icon(Icons.add),
            label: Text(s.rulesNewRule),
          ),
          body: SafeArea(
            child: ListView(padding: const EdgeInsets.fromLTRB(12, 12, 12, 96), children: [
              head(s.rulesNow),
              if (oneOff.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(s.rulesNowEmpty, style: TextStyle(color: t.muted)),
                ),
              for (final r in oneOff)
                _RuleCard(
                  rule: r,
                  text: r.kind == RuleKind.board ? s.rulesTrip(r.line, titleCase(r.stopName)) : '${titleCase(r.stopName)} · ${whenText(r)}',
                  sub: stopped.contains(r.id) ? s.rulesStoppedFromCard : '${r.live ? '${s.alertLiveLockScreen} · ' : ''}${s.rulesUntil(hm(_wallMin(r.untilS!)))}',
                  resume: stopped.contains(r.id) ? () => _resume(d, r) : null,
                  onDelete: () async {
                    d.store.removeRule(r.id);
                    await AlertService.sync(d.store);
                  },
                ),
              head(s.rulesWeekly),
              if (weekly.any((r) => r.enabled)) const _ExactHint(),
              if (weekly.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(s.rulesWeeklyEmpty, style: TextStyle(color: t.muted)),
                ),
              for (final r in weekly)
                _RuleCard(
                  rule: r,
                  text: '${daysText(r.days)}, ${hm(r.startMin)}–${hm(r.endMin)}, ${whenText(r)} ${r.stopIndex >= 0 ? s.ruleEditAt : ''} ${titleCase(r.stopName)}',
                  sub: !r.enabled ? s.rulesPaused : stopped.contains(r.id) ? s.rulesStoppedToday : (r.activeAt(now) ? s.rulesRunningNow : _next(s, r, now)),
                  resume: r.enabled && stopped.contains(r.id) ? () => _resume(d, r) : null,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => RuleEditScreen(rule: r))),
                  toggle: (on) async {
                    d.store.putRule(r.copyWith(enabled: on));
                    await AlertService.sync(d.store);
                  },
                  onDelete: () async {
                    d.store.removeRule(r.id);
                    await AlertService.sync(d.store);
                  },
                ),
            ]),
          ),
        );
      },
    );
  }

  Future<void> _resume(Deps d, Rule r) async {
    await AlertService.resume(d.store, r.id);
    await _check();
  }

  static int _wallMin(int unixS) {
    final a = athensWall(DateTime.fromMillisecondsSinceEpoch(unixS * 1000, isUtc: true));
    return a.hour * 60 + a.minute;
  }

  static String _next(AppLocalizations s, Rule r, DateTime now) {
    final n = nextStartUtc(r, now);
    if (n == null) return '';
    final a = athensWall(now), b = athensWall(n);
    final days = DateTime.utc(b.year, b.month, b.day).difference(DateTime.utc(a.year, a.month, a.day)).inDays;
    final when = days == 0 ? s.rulesToday : days == 1 ? s.rulesTomorrow : s.rulesInDays(days);
    return s.rulesNext(when, hm(r.startMin));
  }
}

class _RuleCard extends StatelessWidget {
  const _RuleCard({required this.rule, required this.text, required this.sub, this.onTap, this.onDelete, this.toggle, this.resume});
  final Rule rule;
  final String text, sub;
  final VoidCallback? onTap, onDelete, resume;
  final ValueChanged<bool>? toggle;

  @override
  Widget build(BuildContext context) {
    final t = context.tones;
    return Card(
      elevation: 0,
      color: t.surface,
      margin: const EdgeInsets.symmetric(vertical: 5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
          child: Row(children: [
            LineBadge(rule.line),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(text, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, height: 1.3)),
                if (sub.isNotEmpty) Text(sub, style: TextStyle(fontSize: 13, color: t.muted)),
              ]),
            ),
            if (resume != null) TextButton(onPressed: resume, child: Text(context.l10n.rulesResume)),
            if (toggle != null) Switch(value: rule.enabled, onChanged: toggle),
            if (onDelete != null) IconButton(tooltip: context.l10n.commonDelete, onPressed: onDelete, icon: const Icon(Icons.close)),
          ]),
        ),
      ),
    );
  }
}

// Weekly rules without the exact-alarm access start late (an inexact alarm): say so, with a way to
// grant it. Checked again whenever the app comes back from the settings screen.
class _ExactHint extends StatefulWidget {
  const _ExactHint();

  @override
  State<_ExactHint> createState() => _ExactHintState();
}

class _ExactHintState extends State<_ExactHint> with WidgetsBindingObserver {
  bool exact = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _check();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState s) {
    if (s == AppLifecycleState.resumed) _check();
  }

  Future<void> _check() async {
    final ok = await AlertService.exactAllowed();
    if (mounted && ok != exact) setState(() => exact = ok);
  }

  @override
  Widget build(BuildContext context) {
    if (exact) return const SizedBox.shrink();
    final t = context.tones;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
      decoration: BoxDecoration(color: t.surface, borderRadius: BorderRadius.circular(16)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(context.l10n.rulesExactHint,
            style: TextStyle(fontSize: 14, height: 1.35)),
        Align(alignment: Alignment.centerRight, child: TextButton(onPressed: AlertService.askExact, child: Text(context.l10n.rulesGrant))),
      ]),
    );
  }
}
