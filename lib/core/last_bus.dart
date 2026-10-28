// «Το τελευταίο προς το σπίτι» (screen 24): Friday and Saturday evening the app suggests an alert for
// the last bus of the day that passes the home stop. The direction is the one with most of the line
// before the stop: coming home from the far end (the centre), not leaving from it.

import 'athens_time.dart';
import 'eta.dart';
import 'models.dart';

const nudgeHour = 21; // the evening notification, Athens

/// The last run of the day that passes the home stop ([ids]: the stop's ids on the line): its variant,
/// the stop's index, the departure from the start, when it passes the stop (s since today's Athens
/// midnight) and the name of its start. null without a timetable direction for it.
({String variant, int i, String t, int atStopS, String from})? homeLast(Map<String, dynamic> schedule, LineStatic st, Iterable<String> ids) {
  final want = ids.toSet();
  ({String variant, int i, double before})? best;
  for (final e in st.variants.entries) {
    final i = e.value.stops.indexWhere(want.contains);
    if (i <= 0) continue; // not on it, or it starts there: leaving home
    final offs = st.offsetsFor(e.key);
    if (i >= offs.length) continue;
    final before = offs[i] - offs.first;
    if (best == null || before > best.before) best = (variant: e.key, i: i, before: before);
  }
  if (best == null) return null;
  final r = lastRun(schedule, st, best.variant, best.i);
  if (r == null) return null;
  final first = st.variants[best.variant]!.stops.first;
  return (variant: best.variant, i: best.i, t: r.t, atStopS: r.atStopS, from: st.stops[first]?.name ?? first);
}

/// Friday or Saturday evening in Athens, 20:00 to midnight. After midnight today's timetable is the
/// next day's already: its last run is tomorrow night's.
bool lastBusEvening(DateTime utc) {
  final w = athensWall(utc);
  return (w.weekday == DateTime.friday || w.weekday == DateTime.saturday) && w.hour >= 20;
}

/// Today's Athens midnight, in UTC.
DateTime athensMidnightUtc(DateTime utc) => athensDayUtc(utc, 0);

/// [s] seconds of wall clock after today's Athens midnight (past 24:00 too), in UTC: on the days the
/// clock changes the offset of that time, not of midnight.
DateTime athensDayUtc(DateTime utc, int s) {
  final w = athensWall(utc);
  final wall = DateTime.utc(w.year, w.month, w.day).add(Duration(seconds: s));
  var at = wall.subtract(const Duration(hours: 2));
  if (athensOffsetHours(at) == 3) at = wall.subtract(const Duration(hours: 3));
  return at;
}

/// The next Friday or Saturday at [nudgeHour] Athens, strictly after [nowUtc].
DateTime nextNudgeUtc(DateTime nowUtc) {
  final wall = athensWall(nowUtc);
  for (var k = 0; k <= 7; k++) {
    final day = DateTime.utc(wall.year, wall.month, wall.day + k);
    if (day.weekday != DateTime.friday && day.weekday != DateTime.saturday) continue;
    final wallAt = day.add(const Duration(hours: nudgeHour));
    var utc = wallAt.subtract(const Duration(hours: 2));
    if (athensOffsetHours(utc) == 3) utc = wallAt.subtract(const Duration(hours: 3));
    if (utc.isAfter(nowUtc)) return utc;
  }
  throw StateError('no Friday in a week');
}
