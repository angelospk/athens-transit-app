// The line card's quality pill (athens-transit-rt docs/QUALITY.md; port of the web's src/lib/quality.ts, v0.2.37):
// one day's stats of a line with a frequent direction: the wait at the stop and how even its buses ran (cv_h of
// `headways`). The day is yesterday, or the day before while yesterday's file is not written yet. No data, no pill.
//
// Not ported: the sparse kind (`origin_otp`, a share of runs on time at the origin). Only the citybus.gr cities
// have it, and the app has Athens and Thessaloniki only.

import 'athens_time.dart';
import 'nearby.dart' show fold;

/// Lit bars of the web's meter, kept as the level: 3 normal (green), 2 yellow, 1 red.
typedef Level = int;

class Headway {
  const Headway({required this.line, required this.dir, required this.n, required this.cvH, required this.waitMin, required this.meanHeadwayS, this.offHeadwayShare});
  final String line;
  final int dir; // Athens 0 Go / 1 Come of OASA's daily schedule; Thessaloniki the GTFS direction_id
  final int n;
  final double cvH, waitMin, meanHeadwayS;
  final double? offHeadwayShare;

  /// Null for an entry that is malformed, or from a day written before 2026-11-13 (no `wait_min`).
  static Headway? tryParse(Object? j) {
    if (j is! Map) return null;
    final line = j['line'], dir = j['dir'], n = j['n'];
    if (line is! String || dir is! int || !_num(n)) return null;
    final cv = j['cv_h'], wait = j['wait_min'], mean = j['mean_headway_s'], off = j['off_headway_share'];
    if (!_num(cv) || !_num(wait) || !_num(mean)) return null;
    return Headway(
      line: line,
      dir: dir,
      n: (n as num).toInt(),
      cvH: (cv as num).toDouble(),
      waitMin: (wait as num).toDouble(),
      meanHeadwayS: (mean as num).toDouble(),
      offHeadwayShare: _num(off) ? (off as num).toDouble() : null,
    );
  }
}

bool _num(Object? v) => v is num && v.isFinite && v >= 0;

/// The parts of a day file (docs/API.md "Daily statistics") the pill reads.
class QualityDay {
  const QualityDay({this.fromH, this.toH, this.headways = const []});
  final int? fromH, toH;
  final List<Headway> headways;

  factory QualityDay.fromJson(Map<String, dynamic> j) {
    final h = j['headways'];
    final by = h is Map ? h['by_line'] : null;
    int? hour(Object? v) => _num(v) ? (v as num).toInt() : null;
    return QualityDay(
      fromH: h is Map ? hour(h['from_h']) : null,
      toH: h is Map ? hour(h['to_h']) : null,
      headways: [if (by is List) for (final x in by) ?Headway.tryParse(x)],
    );
  }
}

/// `parts` is the text split so the number can carry the level's colour; parts.join() == text.
class WaitQuality {
  const WaitQuality({required this.level, required this.text, required this.parts, required this.h, this.fromH, this.toH});
  final Level level;
  final String text;
  final List<String> parts;
  final Headway h;
  final int? fromH, toH;
}

/// Minutes to the nearest half: «4½», «7», «½».
String halfMin(num m) {
  final h = (m * 2).round() / 2, w = h.floor();
  return h == w ? '$w' : (w == 0 ? '½' : '$w½');
}

Level waitLevel(double cvH) => cvH <= 0.39 ? 3 : (cvH <= 0.74 ? 2 : 1);

/// dir: the stats direction of the shown direction, null when it is not known (then no pill).
WaitQuality? lineQuality(QualityDay? day, String line, int? dir) {
  if (day == null || dir == null) return null;
  final h = day.headways.where((x) => x.line == line && x.dir == dir).firstOrNull;
  if (h == null) return null;
  final level = waitLevel(h.cvH);
  final usual = level == 3 ? '' : ' (κανονικά ~${halfMin(h.meanHeadwayS / 2 / 60)}′)';
  final min = '~${halfMin(h.waitMin)}′';
  return WaitQuality(level: level, text: 'αναμονή $min$usual', parts: ['αναμονή ', min, usual], h: h, fromH: day.fromH, toH: day.toH);
}

String _ymd(DateTime d) => '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

/// The date (YYYY-MM-DD) [back] days before today in Athens time.
String daysAgo(DateTime now, int back) {
  final w = athensWall(now);
  return _ymd(DateTime.utc(w.year, w.month, w.day - back));
}

/// The [n] dates that end at [end] (YYYY-MM-DD), oldest first.
List<String> lastDates(String end, int n) {
  final t = DateTime.parse('${end}T12:00:00Z');
  return [for (var i = 0; i < n; i++) _ymd(t.subtract(Duration(days: n - 1 - i)))];
}

/// Yesterday's file once it is written (some hours after midnight, about 13:00 at the latest); until then the day
/// before. A day file that is written is the day shown, even when this line has no data in it.
({QualityDay day, String word, int back})? pickDay(QualityDay? y, QualityDay? before) =>
    y != null ? (day: y, word: 'Χθες', back: 1) : (before != null ? (day: before, word: 'Προχθές', back: 2) : null);

/// One bar of the 7-day chart: the day's wait (minutes) with its level; null for a day without data.
typedef DayBar = ({String date, double value, Level level});
List<DayBar?> dayBars(List<(String, QualityDay?)> days, String line, int? dir) => [
      for (final (date, day) in days)
        if (lineQuality(day, line, dir) case final q?) (date: date, value: q.h.waitMin, level: q.level) else null,
    ];

final _day = RegExp(r'\s*-\s*(δευτερα|τριτη|τεταρτη|πεμπτη|παρασκευη|σαββατο|κυριακη)\s*$');

// "ΠΕΙΡΑΙΑΣ - ΣΥΝΤΑΓΜΑ(ΠΡΟΣΩΡΙΝΗ ΛΟΓΩ ΕΡΓΩΝ)" → "συνταγμα": the part after the last dash, no brackets, accents or
// spaces. OASTH puts the days of a variant at the end: left out, unless the day is the only place after the first one.
String _endOf(String headsign) {
  var s = fold(headsign.replaceAll(RegExp(r'\([^)]*\)'), ''));
  for (var m = _day.firstMatch(s); m != null && s.substring(0, m.start).contains('-'); m = _day.firstMatch(s)) {
    s = s.substring(0, m.start);
  }
  return s.substring(s.lastIndexOf('-') + 1).replaceAll(RegExp(r'\s+'), '');
}

/// The `direction` of the timetable direction going where the variant goes (the web's matchDirection): the same last
/// place, else the one direction whose name contains it or is contained in it. A timetable of one direction (a
/// circular line) is the one of every variant. [dirs]: `directions` of /v1/lines/{id}/schedule.
int? matchDirection(List<Map<String, dynamic>> dirs, String variantHeadsign) {
  final a = _endOf(variantHeadsign);
  final ends = [for (final d in dirs) _endOf('${d['headsign'] ?? ''}')];
  int? dirOf(int i) => (dirs[i]['direction'] as num?)?.toInt();
  if (a.isNotEmpty) {
    final exact = ends.indexOf(a);
    if (exact >= 0) return dirOf(exact);
  }
  final part = a.isEmpty ? <int>[] : [for (var i = 0; i < dirs.length; i++) if (ends[i].isNotEmpty && (a.contains(ends[i]) || ends[i].contains(a))) i];
  if (part.length == 1) return dirOf(part.single);
  return dirs.length == 1 ? dirOf(0) : null;
}
