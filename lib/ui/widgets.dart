import 'package:flutter/material.dart';

import '../core/eta.dart';
import '../data/api.dart';
import '../data/live.dart';
import '../data/store.dart';
import 'theme.dart';

// The app's services, reachable from any screen.
class Deps extends InheritedWidget {
  const Deps({super.key, required this.store, required this.live, required this.api, required super.child});

  final AppStore store;
  final LiveHub live;
  final Api api;

  static Deps of(BuildContext c) => c.dependOnInheritedWidgetOfExactType<Deps>()!;

  @override
  bool updateShouldNotify(Deps old) => false;
}

// A line keeps its palette slot by its place among the user's lines; other lines are neutral.
LineColor lineColor(AppStore store, String line) {
  final i = store.myLines.indexOf(line);
  return i < 0 ? const LineColor(Color(0xFFECEEEA), Color(0xFF1A1C1E)) : palette[i % palette.length];
}

class LineBadge extends StatelessWidget {
  const LineBadge(this.line, {super.key, this.big = false});
  final String line;
  final bool big;

  @override
  Widget build(BuildContext context) {
    final c = lineColor(Deps.of(context).store, line);
    return Container(
      constraints: BoxConstraints(minWidth: big ? 52 : 48),
      padding: EdgeInsets.symmetric(horizontal: 6, vertical: big ? 7 : 6),
      decoration: BoxDecoration(color: c.bg, borderRadius: BorderRadius.circular(8)),
      alignment: Alignment.center,
      child: Text(line, style: TextStyle(color: c.fg, fontSize: big ? 17 : 15, fontWeight: FontWeight.w700)),
    );
  }
}

String mins(int s) => s < 45 ? 'τώρα' : '${(s / 60).round()}′';

// "+2′ καθυστέρηση", "στην ώρα του", or null when unmatched.
(String, Color)? delayNote(BuildContext c, int? delayS) {
  final t = c.tones;
  if (delayS == null) return null;
  if (delayS >= 90) return ('+${(delayS / 60).round()}′ καθυστέρηση', t.late);
  return ('στην ώρα του', t.onTime);
}

// One line at a stop: badge, headsign, note, the next arrival big and the one after.
class ArrivalRow extends StatelessWidget {
  const ArrivalRow({super.key, required this.first, this.then = const [], this.estimate = false, this.trailing, this.onTap, this.big = false});

  final Arrival first;
  final List<Arrival> then;
  final bool estimate; // offline: the times are estimates from the last data
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool big;

  @override
  Widget build(BuildContext context) {
    final t = context.tones;
    final note = delayNote(context, first.delayS);
    final left = first.stopsLeft;
    final parts = [
      if (estimate) 'εκτίμηση' else if (note != null) note.$1,
      if (left != null) left == 1 ? 'επόμενη στάση' : '$left στάσεις',
    ];
    final tilde = estimate ? '~' : '';
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(children: [
          LineBadge(first.line, big: big),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('→ ${titleCase(first.headsign)}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis),
              const SizedBox(height: 3),
              Text(parts.join(' · '),
                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: estimate ? t.muted : note?.$2 ?? t.muted)),
            ]),
          ),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('$tilde${mins(first.etaS)}',
                style: TextStyle(fontSize: big ? 32 : 26, fontWeight: FontWeight.w700, height: 1, fontFeatures: const [FontFeature.tabularFigures()])),
            if (then.isNotEmpty) Text('μετά ${then.take(2).map((a) => mins(a.etaS)).join(', ')}', style: TextStyle(fontSize: 12, color: t.muted)),
          ]),
          if (trailing != null) ...[const SizedBox(width: 10), trailing!],
        ]),
      ),
    );
  }
}

// Groups arrivals by line and direction: first, then the next ones.
List<(Arrival, List<Arrival>)> groupArrivals(List<Arrival> all) {
  final by = <String, List<Arrival>>{};
  for (final a in all) {
    (by['${a.line}|${a.headsign}'] ??= []).add(a);
  }
  final out = [for (final g in by.values) (g.first, g.sublist(1))];
  out.sort((a, b) => a.$1.etaS.compareTo(b.$1.etaS));
  return out;
}

// OASA names are upper case: "ΠΑΝΕΠΙΣΤΗΜΙΟ" -> "Πανεπιστήμιο" is not reversible (accents are lost),
// so names stay as they are except for a gentler case.
String titleCase(String s) {
  final low = s.toLowerCase();
  final words = low.split(' ').map((w) => w.isEmpty ? w : w[0].toUpperCase() + w.substring(1)).join(' ');
  return words.replaceAll(RegExp(r'σ(?=$|[\s.,)\-])'), 'ς');
}

class Dot extends StatelessWidget {
  const Dot(this.color, {super.key, this.size = 8});
  final Color color;
  final double size;
  @override
  Widget build(BuildContext context) =>
      Container(width: size, height: size, decoration: BoxDecoration(color: color, shape: BoxShape.circle));
}

// "Live · ενημέρωση πριν 8″" or the offline note.
class LiveNote extends StatelessWidget {
  const LiveNote({super.key});
  @override
  Widget build(BuildContext context) {
    final live = Deps.of(context).live;
    final t = context.tones;
    return ListenableBuilder(
      listenable: live,
      builder: (context, _) {
        final at = live.lastOkAt;
        if (live.isOffline) {
          final when = at == null ? '' : ' · τελευταία δεδομένα πριν ${mins(live.nowS - at)}';
          return Row(children: [Dot(t.late), const SizedBox(width: 6), Flexible(child: Text('Χωρίς σύνδεση$when', style: TextStyle(fontSize: 12, color: t.muted)))]);
        }
        return Row(children: [
          Dot(t.onTime),
          const SizedBox(width: 6),
          Text(at == null ? 'Live' : 'Live · ενημέρωση πριν ${live.nowS - at}″', style: TextStyle(fontSize: 12, color: t.muted)),
        ]);
      },
    );
  }
}
