// Screen 9 · Ειδοποιήσεις: what watches now (one-off alerts) and the weekly rules, written as sentences.

import 'package:flutter/material.dart';

import '../background/service.dart';
import '../core/athens_time.dart';
import '../core/rules.dart';
import 'rule_edit.dart';
import 'theme.dart';
import 'widgets.dart';

const dayNames = ['Δε', 'Τρ', 'Τε', 'Πε', 'Πα', 'Σα', 'Κυ'];

String daysText(int days) {
  if (days == 0x1F) return 'Δε–Πα';
  if (days == 0x7F) return 'Κάθε μέρα';
  if (days == 0x60) return 'Σα–Κυ';
  return [for (var i = 0; i < 7; i++) if (days & (1 << i) != 0) dayNames[i]].join(', ');
}

String hm(int m) => '${(m ~/ 60).toString().padLeft(2, '0')}:${(m % 60).toString().padLeft(2, '0')}';

String whenText(Rule r) => r.mode == AlertMode.minutes ? '${r.n}′ πριν' : '${r.n} ${r.n == 1 ? 'στάση' : 'στάσεις'} πριν';

class RulesScreen extends StatelessWidget {
  const RulesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final d = Deps.of(context);
    final t = context.tones;
    return ListenableBuilder(
      listenable: d.store,
      builder: (context, _) {
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
            label: const Text('Νέος κανόνας'),
          ),
          body: SafeArea(
            child: ListView(padding: const EdgeInsets.fromLTRB(12, 12, 12, 96), children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                child: Text('Ειδοποιήσεις', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontSize: 28)),
              ),
              head('Τώρα'),
              if (oneOff.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text('Πάτα το καμπανάκι δίπλα σε μια γραμμή στη στάση σου.', style: TextStyle(color: t.muted)),
                ),
              for (final r in oneOff)
                _RuleCard(
                  rule: r,
                  text: '${titleCase(r.stopName)} · ${whenText(r)}',
                  sub: '${r.live ? 'Live στην οθόνη κλειδώματος · ' : ''}ως ${hm(_wallMin(r.untilS!))}',
                  onDelete: () async {
                    d.store.removeRule(r.id);
                    await AlertService.sync(d.store);
                  },
                ),
              head('Κάθε εβδομάδα'),
              if (weekly.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text('Π.χ. «Δε–Πα 08:00–08:40, 5′ πριν το 602 στη στάση σου».', style: TextStyle(color: t.muted)),
                ),
              for (final r in weekly)
                _RuleCard(
                  rule: r,
                  text: '${daysText(r.days)}, ${hm(r.startMin)}–${hm(r.endMin)}, ${whenText(r)} ${r.stopIndex >= 0 ? 'στο' : ''} ${titleCase(r.stopName)}',
                  sub: !r.enabled ? 'Σε παύση' : (r.activeAt(now) ? 'Τρέχει τώρα' : _next(r, now)),
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => RuleEditScreen(rule: r))),
                  toggle: (on) async {
                    d.store.putRule(r.copyWith(enabled: on));
                    await AlertService.sync(d.store);
                  },
                ),
            ]),
          ),
        );
      },
    );
  }

  static int _wallMin(int unixS) {
    final a = athensWall(DateTime.fromMillisecondsSinceEpoch(unixS * 1000, isUtc: true));
    return a.hour * 60 + a.minute;
  }

  static String _next(Rule r, DateTime now) {
    final n = nextStartUtc(r, now);
    if (n == null) return '';
    final days = n.difference(now).inHours ~/ 24;
    final when = days == 0 ? 'σήμερα' : days == 1 ? 'αύριο' : 'σε $days μέρες';
    return 'Επόμενη: $when ${hm(r.startMin)}';
  }
}

class _RuleCard extends StatelessWidget {
  const _RuleCard({required this.rule, required this.text, required this.sub, this.onTap, this.onDelete, this.toggle});
  final Rule rule;
  final String text, sub;
  final VoidCallback? onTap, onDelete;
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
            if (toggle != null) Switch(value: rule.enabled, onChanged: toggle),
            if (onDelete != null) IconButton(tooltip: 'Τέλος', onPressed: onDelete, icon: const Icon(Icons.close)),
          ]),
        ),
      ),
    );
  }
}
