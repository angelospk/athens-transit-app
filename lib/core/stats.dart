// Daily network statistics (athens-transit-rt docs/API.md "Daily statistics"), the "last day" figures.

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
