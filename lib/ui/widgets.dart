import 'package:flutter/material.dart';

import '../core/athens_time.dart';
import '../core/eta.dart';
import '../data/api.dart';
import '../data/live.dart';
import '../data/store.dart';
import 'map_sel.dart';
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
      // No alignment: it would stretch the badge to all the width it is offered (a ListTile's leading).
      child: Text(line, textAlign: TextAlign.center, style: TextStyle(color: c.fg, fontSize: big ? 17 : 15, fontWeight: FontWeight.w700)),
    );
  }
}

// "8″" under a minute, "4′" after.
String ago(int s) => s < 60 ? '$s″' : '${s ~/ 60}′';

String mins(int s) => s < 45 ? 'τώρα' : '${(s / 60).round()}′';

// A delay as words under the minutes: "αργεί 20′", "νωρίτερα 3′", "στην ώρα του" within 90 s.
String delayWords(int delayS) => delayS >= 90
    ? 'αργεί ${(delayS / 60).round()}′'
    : delayS <= -90
        ? 'νωρίτερα ${(-delayS / 60).round()}′'
        : 'στην ώρα του';

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
      if (left != null) left == 1 ? 'επόμενη στάση του' : '$left στάσεις πριν',
      if (estimate) 'εκτίμηση' else if (note != null) note.$1,
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
              Row(children: [
                if (left != null) ...[StopsDots(left, color: lineColor(Deps.of(context).store, first.line).bg), const SizedBox(width: 6)],
                Flexible(
                  child: Text(parts.join(' · '),
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: estimate ? t.muted : note?.$2 ?? t.muted)),
                ),
              ]),
            ]),
          ),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('$tilde${mins(first.etaS)}',
                style: TextStyle(fontSize: big ? 32 : 26, fontWeight: FontWeight.w700, height: 1, fontFeatures: const [FontFeature.tabularFigures()])),
            if (then.isNotEmpty) Text('επόμενο ${then.take(2).map((a) => mins(a.etaS)).join(', ')}', style: TextStyle(fontSize: 12, color: t.muted)),
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

// The bus (a dot in its line's colour), the stops in between, and your stop as a ring: "●··◯".
class StopsDots extends StatelessWidget {
  const StopsDots(this.left, {super.key, required this.color});
  final int left; // stops from the bus to yours
  final Color color;

  @override
  Widget build(BuildContext context) {
    final t = context.tones;
    final between = (left - 1).clamp(0, 3);
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Dot(color, size: 8),
      for (var i = 0; i < between; i++) Padding(padding: const EdgeInsets.only(left: 3), child: Dot(t.muted.withValues(alpha: .5), size: 5)),
      Container(
        width: 9,
        height: 9,
        margin: const EdgeInsets.only(left: 3),
        decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: t.ink, width: 2)),
      ),
    ]);
  }
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
          // No Flexible: the note often sits in a Row beside an Expanded, where its width is unbounded.
          return Row(mainAxisSize: MainAxisSize.min, children: [Dot(t.late), const SizedBox(width: 6), Text('Χωρίς σύνδεση$when', style: TextStyle(fontSize: 12, color: t.muted))]);
        }
        return Row(children: [
          Dot(t.onTime),
          const SizedBox(width: 6),
          Text(at == null ? 'Live' : 'Live · ενημέρωση πριν ${ago(live.nowS - at)}', style: TextStyle(fontSize: 12, color: t.muted)),
        ]);
      },
    );
  }
}

// The grab handle at the top of the map's sheet.
class SheetHandle extends StatelessWidget {
  const SheetHandle({super.key});
  @override
  Widget build(BuildContext context) => Center(
        child: Container(
          width: 32,
          height: 4,
          margin: const EdgeInsets.only(top: 8, bottom: 10),
          decoration: BoxDecoration(color: context.tones.muted.withValues(alpha: .4), borderRadius: BorderRadius.circular(2)),
        ),
      );
}

// Closes what the map's sheet shows; the sheet goes back to the nearest stop.
class CloseSel extends StatelessWidget {
  const CloseSel({super.key});
  @override
  Widget build(BuildContext context) =>
      IconButton(tooltip: 'Κλείσιμο', icon: const Icon(Icons.close), onPressed: () => mapSel.value = null);
}

// The sheet's back arrow, top left: to what was open before (map_sel.dart). Nothing when there is
// nothing to go back to.
class BackSel extends StatelessWidget {
  const BackSel({super.key});
  @override
  Widget build(BuildContext context) => ValueListenableBuilder(
        valueListenable: mapSel,
        builder: (context, _, _) => canMapBack()
            ? IconButton(tooltip: 'Πίσω', icon: const Icon(Icons.arrow_back), onPressed: mapBack)
            : const SizedBox.shrink(),
      );
}

// A line's badge that opens the line: the badge with a small arrow, so it reads as a button.
class LineButton extends StatelessWidget {
  const LineButton(this.line, {super.key, this.variants});
  final String line;
  final Set<String>? variants;

  @override
  Widget build(BuildContext context) {
    final c = lineColor(Deps.of(context).store, line);
    return Tooltip(
      message: 'Η γραμμή $line',
      child: Material(
        color: c.bg,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => mapSel.value = LineSel(line, variants: variants),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 6, 2, 6),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Text(line, style: TextStyle(color: c.fg, fontSize: 17, fontWeight: FontWeight.w700)),
              Icon(Icons.chevron_right, size: 18, color: c.fg),
            ]),
          ),
        ),
      ),
    );
  }
}

// "08:12": the Athens clock time in s seconds from now.
String clockIn(int s) {
  final w = athensWall(DateTime.now().toUtc().add(Duration(seconds: s)));
  return '${w.hour.toString().padLeft(2, '0')}:${w.minute.toString().padLeft(2, '0')}';
}
