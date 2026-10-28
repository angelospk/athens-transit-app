// Daily network statistics (athens-transit-rt docs/API.md "Daily statistics"), the "last day" figures.

import 'athens_time.dart';

const minLineHours = 15.0; // vehicle-hours of speed samples before a line is ranked
const minLineTrips = 20; // measured trips before a line is ranked by missed trips

int _i(Object? v) => (v as num?)?.toInt() ?? 0;
double _d(Object? v) => (v as num?)?.toDouble() ?? 0;
List<Map<String, dynamic>> _list(Object? v) => [for (final x in v as List? ?? const []) x as Map<String, dynamic>];

class HourStats {
  HourStats.fromJson(Map<String, dynamic> j)
      : h = _i(j['h']),
        fixes = _i(j['fixes']),
        vehicles = _i(j['vehicles']),
        lines = _i(j['lines']),
        distM = _d(j['dist_m']),
        timeS = _d(j['time_s']);
  final int h, fixes, vehicles, lines;
  final double distM, timeS;
}

class LineStats {
  LineStats.fromJson(Map<String, dynamic> j)
      : line = j['line'] as String,
        fixes = _i(j['fixes']),
        vehicles = _i(j['vehicles']),
        distM = _d(j['dist_m']),
        timeS = _d(j['time_s']);
  final String line;
  final int fixes, vehicles;
  final double distM, timeS;
}

class TripLine {
  TripLine.fromJson(Map<String, dynamic> j)
      : line = j['line'] as String,
        planned = _i(j['planned']),
        run = _i(j['run']),
        partial = _i(j['partial']),
        missed = _i(j['missed']),
        unmeasured = _i(j['unmeasured']);
  final String line;
  final int planned, run, partial, missed, unmeasured;
}

class TripStats {
  TripStats.fromJson(Map<String, dynamic> j)
      : gtfs = j['gtfs'] as String? ?? '',
        gtfsExpired = j['gtfs_expired'] == true,
        planned = _i(j['planned']),
        run = _i(j['run']),
        partial = _i(j['partial']),
        missed = _i(j['missed']),
        unmeasured = _i(j['unmeasured']),
        byLine = [for (final l in _list(j['by_line'])) TripLine.fromJson(l)];
  final String gtfs;
  final bool gtfsExpired;
  final int planned, run, partial, missed, unmeasured;
  final List<TripLine> byLine;
}

class DayStats {
  DayStats.fromJson(Map<String, dynamic> j)
      : date = j['date'] as String,
        tz = j['tz'] as String? ?? '',
        generatedAt = _i(j['generated_at']),
        firstFix = _i(j['first_fix']),
        lastFix = _i(j['last_fix']),
        fixes = _i(j['fixes']),
        vehicles = _i(j['vehicles']),
        lines = _i(j['lines']),
        hours = [for (final h in _list(j['hours'])) HourStats.fromJson(h)],
        byLine = [for (final l in _list(j['by_line'])) LineStats.fromJson(l)],
        trips = j['trips'] == null ? null : TripStats.fromJson(j['trips'] as Map<String, dynamic>);
  final String date, tz;
  final int generatedAt, firstFix, lastFix, fixes, vehicles, lines;
  final List<HourStats> hours;
  final List<LineStats> byLine;
  final TripStats? trips;

  // Pooled: all metres over all seconds, never a mean of hourly means.
  double? get kmh {
    final dist = hours.fold(0.0, (s, h) => s + h.distM);
    final time = hours.fold(0.0, (s, h) => s + h.timeS);
    return time > 0 ? dist / time * 3.6 : null;
  }
}

typedef Ranked = ({String line, double kmh, int km, int hours});

// The n slowest and n fastest lines with enough samples; a line is never in both lists.
({List<Ranked> slow, List<Ranked> fast, int eligible}) ranking(DayStats d, int n, {double minHours = minLineHours}) {
  final all = <Ranked>[
    for (final l in d.byLine)
      if (l.timeS >= minHours * 3600)
        (line: l.line, kmh: l.distM / l.timeS * 3.6, km: (l.distM / 1000).round(), hours: (l.timeS / 3600).round()),
  ]..sort((a, b) {
      final c = a.kmh.compareTo(b.kmh);
      return c != 0 ? c : a.line.compareTo(b.line);
    });
  final k = n < all.length ~/ 2 ? n : all.length ~/ 2;
  final from = all.length - n > k ? all.length - n : k;
  return (slow: all.sublist(0, k), fast: all.sublist(from).reversed.toList(), eligible: all.length);
}

typedef Worst = ({String line, int missed, int measured});
typedef TripShare = ({double share, int run, int measured, bool expired, String gtfs, List<Worst> worst, int unseen});

// Share of the measured scheduled trips that ran, and the n lines with the largest share never seen.
// A line with no trip seen at all is counted in `unseen`, not ranked: it may not have run at all,
// or its timetable changed (an expired GTFS still lists it).
TripShare? tripShare(DayStats d, {int n = 5}) {
  final t = d.trips;
  final measured = t == null ? 0 : t.planned - t.unmeasured;
  if (t == null || measured <= 0) return null;
  final worst = <Worst>[
    for (final l in t.byLine)
      if (l.run + l.partial > 0 && l.missed > 0 && l.planned - l.unmeasured >= minLineTrips)
        (line: l.line, missed: l.missed, measured: l.planned - l.unmeasured),
  ]..sort((a, b) {
      final c = (b.missed / b.measured).compareTo(a.missed / a.measured);
      return c != 0 ? c : a.line.compareTo(b.line);
    });
  final unseen = t.byLine.where((l) => l.planned > l.unmeasured && l.run + l.partial == 0).length;
  return (
    share: t.run / measured,
    run: t.run,
    measured: measured,
    expired: t.gtfsExpired,
    gtfs: t.gtfs,
    worst: worst.take(n).toList(),
    unseen: unseen,
  );
}

// ---- Long-term: the stored days combined. Speeds are pooled (sum dist / sum time), never a mean of means.

const longDays = 28; // newest day files read for the long-term tab

double? _kmh(double distM, double timeS) => timeS > 0 ? distM / timeS * 3.6 : null;

// The local hour of a unix time. The day files are always Athens time, so the tz field is not read.
int _athensHour(int unixS) => athensWall(DateTime.fromMillisecondsSinceEpoch(unixS * 1000, isUtc: true)).hour;

// Hours the day is partial in: before its first fix or after its last (history started late,
// or the day's end is missing), and service hours (05:00-24:00) without a single fix (an outage).
List<int> gaps(DayStats d) {
  if (d.fixes == 0) return [for (final h in d.hours) h.h];
  final first = _athensHour(d.firstFix), last = _athensHour(d.lastFix);
  return [for (final h in d.hours) if (h.h < first || h.h > last || (h.h >= 5 && h.fixes == 0)) h.h];
}

// A day without gaps; partial days are left out of every long-term figure.
bool complete(DayStats d) => gaps(d).isEmpty;

// Saturday and Sunday, from the calendar date of the day file.
bool isWeekend(String date) => DateTime.parse('${date}T12:00:00Z').weekday >= DateTime.saturday;

typedef HourBand = ({int h, double? kmh, double? min, double? max, int n});

// Per local hour: pooled km/h over the days, the slowest and fastest day, and the days with a speed.
List<HourBand> hourBand(List<DayStats> days) => [
      for (var h = 0; h < 24; h++) _band(h, days),
    ];

HourBand _band(int h, List<DayStats> days) {
  var dist = 0.0, time = 0.0, n = 0;
  double? min, max;
  for (final d in days) {
    final x = d.hours[h];
    final v = _kmh(x.distM, x.timeS);
    if (v == null) continue;
    dist += x.distM;
    time += x.timeS;
    n++;
    if (min == null || v < min) min = v;
    if (max == null || v > max) max = v;
  }
  return (h: h, kmh: _kmh(dist, time), min: min, max: max, n: n);
}

typedef TypeHour = ({int h, double? vehicles, double? kmh});
typedef DayType = ({int days, double? kmh, List<TypeHour> hours});

// Weekdays and weekend apart: vehicles per hour as a plain mean of the days (a count), speed pooled.
({DayType weekday, DayType weekend}) byDayType(List<DayStats> days) {
  DayType group(List<DayStats> ds) => (
        days: ds.length,
        kmh: _kmh(ds.fold(0.0, (s, d) => s + d.hours.fold(0.0, (t, x) => t + x.distM)),
            ds.fold(0.0, (s, d) => s + d.hours.fold(0.0, (t, x) => t + x.timeS))),
        hours: [
          for (var h = 0; h < 24; h++)
            (
              h: h,
              vehicles: ds.isEmpty ? null : ds.fold(0, (s, d) => s + d.hours[h].vehicles) / ds.length,
              kmh: _kmh(ds.fold(0.0, (s, d) => s + d.hours[h].distM), ds.fold(0.0, (s, d) => s + d.hours[h].timeS)),
            ),
        ],
      );
  return (
    weekday: group([for (final d in days) if (!isWeekend(d.date)) d]),
    weekend: group([for (final d in days) if (isWeekend(d.date)) d]),
  );
}

typedef Trend = ({String line, double kmh, double base, double change});

// The newest day's lines against the earlier days of the same type (weekday or weekend), pooled.
// Both sides need minHours of speed samples. null: fewer than 2 earlier days of that type.
({String date, bool weekend, int baseDays, int eligible, List<Trend> slower, List<Trend> faster})? lineTrends(
    List<DayStats> days, int n,
    {double minHours = minLineHours}) {
  final sorted = [...days]..sort((a, b) => a.date.compareTo(b.date));
  if (sorted.isEmpty) return null;
  final latest = sorted.last;
  final weekend = isWeekend(latest.date);
  final base = [for (final d in sorted.take(sorted.length - 1)) if (isWeekend(d.date) == weekend) d];
  if (base.length < 2) return null;
  final sums = <String, ({double dist, double time})>{};
  for (final d in base) {
    for (final l in d.byLine) {
      final s = sums[l.line] ?? (dist: 0.0, time: 0.0);
      sums[l.line] = (dist: s.dist + l.distM, time: s.time + l.timeS);
    }
  }
  final all = <Trend>[];
  for (final l in latest.byLine) {
    final s = sums[l.line];
    if (s == null || l.timeS < minHours * 3600 || s.time < minHours * 3600 || s.dist <= 0) continue;
    final now = l.distM / l.timeS * 3.6, was = s.dist / s.time * 3.6;
    all.add((line: l.line, kmh: now, base: was, change: now / was - 1));
  }
  int byChange(Trend a, Trend b, {required bool up}) {
    final c = up ? b.change.compareTo(a.change) : a.change.compareTo(b.change);
    return c != 0 ? c : a.line.compareTo(b.line);
  }

  final slower = [for (final t in all) if (t.change < 0) t]..sort((a, b) => byChange(a, b, up: false));
  final faster = [for (final t in all) if (t.change > 0) t]..sort((a, b) => byChange(a, b, up: true));
  return (
    date: latest.date,
    weekend: weekend,
    baseDays: base.length,
    eligible: all.length,
    slower: slower.take(n).toList(),
    faster: faster.take(n).toList(),
  );
}

bool _num(Object? v) => v is num && v.isFinite && v >= 0;

// A day file as docs/API.md describes it, and the day that was asked for. The zone is always
// Europe/Athens: gaps() reads the local hour without a timezone database.
bool validDay(Map<String, dynamic> j, String date) {
  if (j['version'] != 1 || j['date'] != date || j['tz'] != 'Europe/Athens') return false;
  if (![j['first_fix'], j['last_fix'], j['fixes']].every(_num)) return false;
  final hours = j['hours'], byLine = j['by_line'];
  if (hours is! List || hours.length != 24 || byLine is! List) return false;
  for (var i = 0; i < 24; i++) {
    final h = hours[i];
    if (h is! Map<String, dynamic> || h['h'] != i) return false;
    if (![h['fixes'], h['vehicles'], h['dist_m'], h['time_s']].every(_num)) return false;
  }
  for (final l in byLine) {
    if (l is! Map<String, dynamic> || l['line'] is! String) return false;
    if (![l['dist_m'], l['time_s']].every(_num)) return false;
  }
  return true;
}
