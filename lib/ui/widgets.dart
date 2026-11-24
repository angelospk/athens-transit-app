import 'dart:math';

import 'package:flutter/material.dart';

import '../core/athens_time.dart';
import '../core/eta.dart';
import '../core/names.dart';
import '../core/nearby.dart';
import '../data/api.dart';
import '../data/live.dart';
import '../data/store.dart';
import 'map_sel.dart';
import 'stop_screen.dart' show StopRef;
import 'theme.dart';

export '../core/names.dart' show titleCase;

// The app's services, reachable from any screen.
class Deps extends InheritedWidget {
  const Deps({super.key, required this.store, required this.live, required this.api, required super.child});

  final AppStore store;
  final LiveHub live;
  final Api api;

  static Deps of(BuildContext c) => c.dependOnInheritedWidgetOfExactType<Deps>()!;

  @override
  bool updateShouldNotify(Deps old) => old.api != api || old.live != live; // a city switch
}

// Each line's operator colours (lines.json `color`, `text_color`) of the open city, as the web shows them. Empty
// until the city's lines load; a city switch loads them again (main.dart).
final operatorColors = ValueNotifier<Map<String, LineColor>>(const {});
Api? _colorsOf;

Future<void> loadLineColors(Api api) async {
  _colorsOf = api;
  try {
    final lines = await api.lines();
    if (!identical(_colorsOf, api)) return; // another city opened meanwhile
    operatorColors.value = {
      for (final l in lines)
        if (hexColor(l.color) case final bg?) l.id: LineColor(bg, hexColor(l.textColor) ?? Colors.white),
    };
  } catch (_) {/* badges stay neutral */}
}

// "#1a56c4" → the colour; null for anything else.
Color? hexColor(String s) {
  final v = s.length == 7 && s.startsWith('#') ? int.tryParse(s.substring(1), radix: 16) : null;
  return v == null ? null : Color(0xFF000000 | v);
}

const _neutral = LineColor(Color(0xFFEFF0EC), Color(0xFF16181B));

// A badge's colours: the line's, or for a line with none the theme's surface and ink (light and dark).
LineColor badgeColor(BuildContext context, String line) {
  final c = lineColor(Deps.of(context).store, line);
  final t = context.tones;
  return identical(c, _neutral) ? LineColor(t.surface, t.ink) : c;
}

// A line keeps its palette slot by its place among the user's lines (its route on the map has that colour);
// other lines take their operator colour, neutral until the lines load.
LineColor lineColor(AppStore store, String line) {
  final i = store.myLines.indexOf(line);
  return i < 0 ? operatorColors.value[line] ?? _neutral : palette[i % palette.length];
}

// The shared line badge (docs/design-unify-2026-11.md in the web repo): min 44 × 30, radius 8, 14 / 800.
class LineBadge extends StatelessWidget {
  const LineBadge(this.line, {super.key, this.big = false});
  final String line;
  final bool big;

  @override
  Widget build(BuildContext context) => ValueListenableBuilder(
        valueListenable: operatorColors,
        builder: (context, _, _) {
          final c = badgeColor(context, line);
          return Container(
            constraints: BoxConstraints(minWidth: big ? 50 : 44, minHeight: big ? 34 : 30),
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(color: c.bg, borderRadius: BorderRadius.circular(Ds.rSm)),
            // Factors of 1: only as wide as its text, also where the width offered is larger (a ListTile's leading).
            child: Center(
              widthFactor: 1,
              heightFactor: 1,
              child: Text(line, textAlign: TextAlign.center, style: Ds.badge.copyWith(color: c.fg, fontSize: big ? 16 : 14)),
            ),
          );
        },
      );
}

// The live mark: a dot and two arcs, on a time that comes from a vehicle's GPS (the web's Icon «live» draws the
// same shape on the same 20-unit grid).
class LiveMark extends StatelessWidget {
  const LiveMark({super.key, this.size = 12, this.color});
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) => Semantics(
        label: 'ζωντανά',
        child: CustomPaint(size: Size.square(size), painter: _LivePainter(color ?? context.tones.accent)),
      );
}

class _LivePainter extends CustomPainter {
  _LivePainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final k = size.width / 20;
    final p = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.6 * k
      ..strokeCap = StrokeCap.round;
    const c = Offset(5, 15);
    canvas.drawCircle(c * k, 2.2 * k, Paint()..color = color);
    for (final r in [5.8, 11.4]) {
      canvas.drawArc(Rect.fromCircle(center: c * k, radius: r * k), -pi / 2, pi / 2, false, p);
    }
  }

  @override
  bool shouldRepaint(_LivePainter old) => old.color != color;
}

// An arrival time in the shared ETA style: a live time with the live mark in ink, an estimate or timetable time
// muted with no mark, «τώρα» smaller and in the accent. [big]: the first row of a stop (28), else 24.
class EtaText extends StatelessWidget {
  const EtaText(this.text, {super.key, required this.live, this.big = false});
  final String text;
  final bool live, big;

  @override
  Widget build(BuildContext context) {
    final t = context.tones;
    final now = text.endsWith('τώρα');
    final size = now ? (big ? 19.0 : 17.0) : (big ? 28.0 : 24.0);
    return Row(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (live) Padding(padding: EdgeInsets.only(top: size * .2, right: 3), child: LiveMark(size: big ? 13 : 11)),
      Text(text,
          style: TextStyle(
            fontSize: size,
            height: 1.05,
            fontWeight: live ? FontWeight.w800 : FontWeight.w700,
            letterSpacing: now ? 0 : -0.4,
            color: now ? t.accent : live ? t.ink : t.muted,
            fontFeatures: Ds.tabular,
          )),
    ]);
  }
}

// "23:08:14": the Athens clock at Unix time s, to the second.
String clockAt(int s) {
  final w = athensWall(DateTime.fromMillisecondsSinceEpoch(s * 1000, isUtc: true));
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(w.hour)}:${two(w.minute)}:${two(w.second)}';
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

// "αργεί 2′", "στην ώρα του", or null when unmatched.
(String, Color)? delayNote(BuildContext c, int? delayS) {
  final t = c.tones;
  if (delayS == null) return null;
  if (delayS >= 90) return (delayWords(delayS), t.late);
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
    // One fact under the headsign: an estimate, or a delay, or how far the bus is.
    final late = !estimate && (first.delayS ?? 0) >= 90;
    final far = !estimate && !late && left != null;
    final fact = estimate
        ? 'εκτίμηση'
        : late
            ? note!.$1
            : far
                ? (left == 1 ? '1 στάση μακριά' : '$left στάσεις μακριά')
                : note?.$1 ?? '';
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
              Text('→ ${towards(first)}', style: Ds.bodyStrong, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 3),
              Row(children: [
                if (far) ...[StopsDots(left, color: lineColor(Deps.of(context).store, first.line).bg), const SizedBox(width: 6)],
                Flexible(
                  child: Text(fact,
                      overflow: TextOverflow.ellipsis,
                      style: Ds.note.copyWith(color: late ? t.late : !estimate && !far && note != null ? t.onTime : t.muted)),
                ),
              ]),
            ]),
          ),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            EtaText('$tilde${mins(first.etaS)}', live: !estimate, big: big),
            if (then.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text('μετά ${then.take(2).map((a) => mins(a.etaS)).join(', ')}', style: TextStyle(fontSize: 12, color: t.muted)),
              ),
          ]),
          if (trailing != null) ...[const SizedBox(width: 10), trailing!],
        ]),
      ),
    );
  }
}

/// The rows of a stop card: the starred lines on top (all of them), then the others by arrival, up to
/// [cap] rows in all unless [all]; [hidden] is how many «Όλες οι γραμμές» would add.
({List<(Arrival, List<Arrival>)> mine, List<(Arrival, List<Arrival>)> others, int hidden}) stopRows(
    List<(Arrival, List<Arrival>)> groups, Set<String> starred,
    {bool all = false, int cap = 6}) {
  final mine = groups.where((x) => starred.contains(x.$1.line)).toList();
  final rest = groups.where((x) => !starred.contains(x.$1.line)).toList();
  final room = all ? rest.length : (cap - mine.length).clamp(0, rest.length);
  return (mine: mine, others: rest.take(room).toList(), hidden: rest.length - room);
}

// Groups arrivals by line and direction: first, then the next ones. The way back of a loop is its own
// direction: the bus runs the other way along the same headsign.
List<(Arrival, List<Arrival>)> groupArrivals(List<Arrival> all) {
  final by = <String, List<Arrival>>{};
  for (final a in all) {
    (by['${a.line}|${a.headsign}|${a.back}'] ??= []).add(a);
  }
  final out = [for (final g in by.values) (g.first, g.sublist(1))];
  out.sort((a, b) => a.$1.etaS.compareTo(b.$1.etaS));
  return out;
}

// Where the bus goes: the headsign, or on a loop after the turn, the way back.
String towards(Arrival a) => a.back == null ? titleCase(a.headsign) : '${titleCase(a.back!)} (επιστροφή)';

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

// «Τελευταία ενημέρωση 23:08:14» (the last fetch that worked; it changes with each automatic refresh) or the offline note.
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
          Text(at == null ? 'Live' : 'Τελευταία ενημέρωση ${clockAt(at)}', style: TextStyle(fontSize: 12, color: t.muted)),
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

// The sheet's «‹ Πίσω», top left, named after the level before (map_sel.dart backLabel); from the
// first level it goes back to the home sheet.
class BackSel extends StatelessWidget {
  const BackSel({super.key});
  @override
  Widget build(BuildContext context) => ValueListenableBuilder(
        valueListenable: mapSel,
        builder: (context, sel, _) => sel == null
            ? const SizedBox.shrink()
            : ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 150, minHeight: 48),
                child: TextButton.icon(
                  style: TextButton.styleFrom(padding: const EdgeInsets.fromLTRB(4, 0, 10, 0), foregroundColor: context.tones.ink),
                  onPressed: mapBack,
                  icon: const Icon(Icons.chevron_left, size: 22),
                  label: Text(backLabel(), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                ),
              ),
      );
}

// A line's badge that opens the line: the badge with a small arrow, so it reads as a button.
class LineButton extends StatelessWidget {
  const LineButton(this.line, {super.key, this.variants, this.stop});
  final String line;
  final Set<String>? variants;
  final StopRef? stop; // the stop the bus was opened from: the line card's own stop

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
          onTap: () => mapSel.value = LineSel(line, variants: variants, stop: stop),
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

/// «↗ προς ΜΟΥΣΕΙΟ · ΠΟΛΥΓΩΝΟ»: which way the buses leave a stop. The arrow points to the bearing (north up);
/// no bearing, no arrow.
class TowardRow extends StatelessWidget {
  const TowardRow(this.toward, {super.key, this.size = 13});
  final Toward toward;
  final double size;

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(fontSize: size, color: context.tones.muted);
    return Row(mainAxisSize: MainAxisSize.min, children: [
      if (toward.bearing case final b?) ...[
        Transform.rotate(angle: b * pi / 180, child: Icon(Icons.north, size: size + 1, color: context.tones.muted)),
        const SizedBox(width: 3),
      ],
      Flexible(child: Text(towardText(toward), style: style, maxLines: 1, overflow: TextOverflow.ellipsis)),
    ]);
  }
}
