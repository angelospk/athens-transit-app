// The line card's quality pill (web v0.2.37, QualityPill.svelte; mockup athens-transit-map docs/mockups/quality-v3.html):
// one line whose number is coloured by its level, no meter. A tap opens the day's detail and the last 7 days under it;
// the 7 day files load only then. No data for the shown direction, no pill.

import 'dart:math';

import 'package:flutter/material.dart';

import '../core/live_quality.dart';
import '../core/quality.dart';
import 'levels.dart';
import 'theme.dart';
import 'widgets.dart';

QualityLevel _level(Level l) => l == 3 ? QualityLevel.normal : (l == 2 ? QualityLevel.worse : QualityLevel.muchWorse);

const _levelWords = {
  QualityLevel.normal: 'κανονικά',
  QualityLevel.worse: 'λίγο χειρότερα από το συνηθισμένο',
  QualityLevel.muchWorse: 'πολύ χειρότερα από το συνηθισμένο',
  QualityLevel.unknown: '',
};

class QualityPill extends StatefulWidget {
  /// [line]: the native line id; [headsign]: the shown direction's headsign (what the day's timetable is matched on),
  /// null while the line shows several directions at once (then the stats direction is not known: no pill).
  const QualityPill({super.key, required this.line, required this.headsign});
  final String line;
  final String? headsign;

  @override
  State<QualityPill> createState() => _QualityPillState();
}

class _QualityPillState extends State<QualityPill> {
  ({QualityDay day, String word, String date})? _shown;
  List<Map<String, dynamic>>? _dirs; // the timetable's directions: only asked for a line with headways
  bool _started = false, _open = false;
  List<(String, QualityDay?)>? _week;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _load();
  }

  Future<void> _load() async {
    final api = Deps.of(context).api;
    try {
      final shown = await api.shownDay();
      if (!mounted) return;
      setState(() => _shown = shown);
      if (shown == null || !shown.day.headways.any((h) => h.line == widget.line)) return;
      final sched = await api.cachedSchedule(widget.line);
      final dirs = sched?['directions'];
      if (mounted && dirs is List) setState(() => _dirs = [for (final d in dirs) if (d is Map<String, dynamic>) d]);
    } catch (_) {/* no pill */}
  }

  Future<void> _toggle(String date) async {
    setState(() => _open = !_open);
    if (!_open) return;
    // Every open asks dayFile again: its cache keeps the found files and retries a failed one.
    final api = Deps.of(context).api;
    final week = await Future.wait([for (final d in lastDates(date, 7)) api.dayFile(d).then((day) => (d, day))]);
    if (mounted && _open) setState(() => _week = week);
  }

  @override
  Widget build(BuildContext context) {
    final shown = _shown, hs = widget.headsign, dirs = _dirs;
    if (shown == null || hs == null || dirs == null) return const SizedBox.shrink();
    final dir = matchDirection(dirs, hs);
    final q = lineQuality(shown.day, widget.line, dir);
    if (q == null) return const SizedBox.shrink();
    final t = context.tones;
    final lv = _level(q.level);
    final plain = TextStyle(fontSize: 13, height: 1.35, color: t.ink);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(color: t.surface, borderRadius: BorderRadius.circular(10)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Semantics(
          button: true,
          expanded: _open,
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () => _toggle(shown.date),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 36),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(children: [
                  Expanded(
                    child: Text.rich(
                      TextSpan(style: plain, children: [
                        TextSpan(text: '${shown.word} · ', style: TextStyle(color: t.muted)),
                        TextSpan(style: const TextStyle(fontWeight: FontWeight.w600), children: [
                          TextSpan(text: q.parts[0]),
                          TextSpan(text: q.parts[1], style: TextStyle(color: levelText(context, lv))),
                          TextSpan(text: q.parts[2]),
                        ]),
                      ]),
                      semanticsLabel: '${shown.word} · ${q.text}, ${_levelWords[lv]}',
                    ),
                  ),
                  const SizedBox(width: 9),
                  AnimatedRotation(
                    turns: _open ? .25 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(Icons.chevron_right, size: 18, color: t.muted),
                  ),
                ]),
              ),
            ),
          ),
        ),
        if (_open) _more(context, q, shown),
      ]),
    );
  }

  Widget _more(BuildContext context, WaitQuality q, ({QualityDay day, String word, String date}) shown) {
    final t = context.tones;
    final h = q.h;
    final week = _week;
    final bars = week == null ? null : dayBars(week, widget.line, matchDirection(_dirs!, widget.headsign!));
    final window = q.fromH != null && q.toH != null ? ' ${q.fromH.toString().padLeft(2, '0')}–${q.toH.toString().padLeft(2, '0')}' : '';
    final off = h.offHeadwayShare != null ? '· ${(h.offHeadwayShare! * 10).round()} στις 10 ήρθαν μαζί με άλλο ή μετά από μεγάλο κενό' : '';
    final small = TextStyle(fontSize: 12, color: t.muted, height: 1.4);
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.only(top: 6, bottom: 4),
          child: Text('Μέση αναμονή στη στάση, τελευταίες 7 μέρες', style: small.copyWith(fontWeight: FontWeight.w600)),
        ),
        if (bars == null)
          Text('Φόρτωση…', style: small)
        else
          Semantics(
            label: [
              for (var i = 0; i < bars.length; i++)
                '${_dayName(week![i].$1, i == bars.length - 1, shown.word)}: ${bars[i] == null ? 'χωρίς στοιχεία' : '${halfMin(bars[i]!.value)}′'}',
            ].join(', '),
            child: ExcludeSemantics(
              child: AspectRatio(
                aspectRatio: _w / (_h + 30),
                child: CustomPaint(
                  painter: _WaitChart(
                    bars: bars,
                    names: [for (var i = 0; i < bars.length; i++) _dayName(week![i].$1, i == bars.length - 1, shown.word)],
                    ref: h.meanHeadwayS / 2 / 60,
                    ink: t.ink,
                    muted: t.muted,
                    rule: t.rule,
                  ),
                ),
              ),
            ),
          ),
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            'Διακεκομμένη: η αναμονή αν τα λεωφορεία έρχονταν ομοιόμορφα (μισό headway).\n'
            '${shown.word}: ${h.n + 1} διελεύσεις$window, κάθε ~${halfMin(h.meanHeadwayS / 60)}′ κατά μέσο όρο$off.',
            style: small,
          ),
        ),
      ]),
    );
  }
}

const _wd = ['Κυ', 'Δε', 'Τρ', 'Τε', 'Πε', 'Πα', 'Σα'];
String _dayName(String date, bool last, String word) => last ? word.toLowerCase() : _wd[DateTime.parse('${date}T12:00:00Z').weekday % 7];

// Chart geometry in the web's SVG user units (it scales to the card's width): 7 bars, a dashed line at the wait of
// evenly spaced buses, the value above each bar, the day under it; the last day (the one the pill shows) is full.
const _w = 320.0, _h = 92.0;

class _WaitChart extends CustomPainter {
  _WaitChart({required this.bars, required this.names, required this.ref, required this.ink, required this.muted, required this.rule});
  final List<DayBar?> bars;
  final List<String> names;
  final double ref;
  final Color ink, muted, rule;

  @override
  void paint(Canvas canvas, Size size) {
    final k = size.width / _w;
    canvas.scale(k);
    canvas.translate(0, 14); // the viewBox starts at y = -14
    final top = bars.fold<double>(ref, (m, b) => max(m, b?.value ?? 0)) * 1.15;
    double y(double v) => _h - v / top * _h;
    void text(String s, double cx, double cy, {Color? c, bool bold = false}) {
      final tp = TextPainter(
        text: TextSpan(text: s, style: TextStyle(fontSize: 11, color: c ?? muted, fontWeight: bold ? FontWeight.w700 : FontWeight.w400, fontFeatures: const [FontFeature.tabularFigures()])),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(cx - tp.width / 2, cy - tp.height * .75));
    }

    final bw = _w / bars.length;
    for (var i = 0; i < bars.length; i++) {
      final b = bars[i], last = i == bars.length - 1, cx = i * bw + bw / 2;
      if (b != null) {
        final rect = RRect.fromRectAndRadius(Rect.fromLTWH(i * bw + bw * .18, y(b.value), bw * .64, _h - y(b.value)), const Radius.circular(3));
        canvas.drawRRect(rect, Paint()..color = levelFill(_level(b.level)).withValues(alpha: last ? 1 : .55));
        text('${halfMin(b.value)}′', cx, y(b.value) - 4, c: ink, bold: last);
      } else {
        text('—', cx, _h - 4);
      }
      text(names[i], cx, _h + 14, bold: last);
    }
    canvas.drawLine(Offset(0, _h), Offset(_w, _h), Paint()..color = rule);
    // The dashed line at the even-service wait.
    final dash = Paint()..color = ink.withValues(alpha: .55)..strokeWidth = 1;
    for (var x = 0.0; x < _w; x += 6) {
      canvas.drawLine(Offset(x, y(ref)), Offset(min(x + 3, _w), y(ref)), dash);
    }
  }

  @override
  bool shouldRepaint(_WaitChart old) => old.bars != bars || old.names != names || old.ref != ref || old.ink != ink;
}
