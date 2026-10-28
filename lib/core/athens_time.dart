// Athens wall clock without a timezone database: EU rules (EEST from the last Sunday of March
// 01:00 UTC to the last Sunday of October 01:00 UTC).

DateTime _lastSunday(int year, int month, int hourUtc) {
  final last = DateTime.utc(year, month, 31);
  return DateTime.utc(year, month, 31 - last.weekday % DateTime.daysPerWeek, hourUtc);
}

int athensOffsetHours(DateTime utc) {
  final u = utc.toUtc();
  final start = _lastSunday(u.year, 3, 1), end = _lastSunday(u.year, 10, 1);
  return !u.isBefore(start) && u.isBefore(end) ? 3 : 2;
}

/// A UTC-flagged DateTime whose fields read as the Athens wall clock.
DateTime athensWall(DateTime utc) {
  final u = utc.toUtc();
  return u.add(Duration(hours: athensOffsetHours(u)));
}

/// A GTFS "HH:MM[:SS]" as the clock reads it: "24:30" (past midnight of its service day) is "00:30".
String gtfsClock(String hm) {
  final p = hm.split(':');
  final h = p.length >= 2 ? int.tryParse(p[0]) : null;
  if (h == null) return hm;
  return '${(h % 24).toString().padLeft(2, '0')}:${p[1]}';
}
