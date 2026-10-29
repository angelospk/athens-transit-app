// «Γυρνάς σπίτι»: from where the user is to the «Σπίτι» place. The direct lines home (the planner's
// search), where to board each, and the last run of each past that stop today. Sorted, the first one
// is when the options start to vanish («το πρώτο από τα τελευταία»).

import 'athens_time.dart';
import 'eta.dart';
import 'last_bus.dart' show athensDayUtc;
import 'geo.dart';
import 'models.dart';
import 'trip.dart';

typedef HomeBoard = ({String line, String variant, int i, String stop, Pt at, double min});

/// The direct ways home from [from]: per line its quickest variant and the stop to board at, best
/// first, at most [max].
List<HomeBoard> homeBoards(TripIndex ix, Pt from, Pt home, {Set<String>? known, int max = 4}) => [
      for (final l in findTrips(ix, [from], [home], walkM, known).take(max))
        if (l.variants.isNotEmpty)
          () {
            final v = l.variants.reduce((a, b) => b.min < a.min ? b : a);
            final s = ix.s[v.from];
            return (line: l.line, variant: v.id, i: v.i, stop: s.$1, at: (s.$2, s.$3), min: l.min);
          }(),
    ];

typedef HomeLast = ({String line, String stop, int atS});

/// Now in the timetable's day: seconds since Athens midnight, and past 24 h until 04:00, when the
/// night's last runs ("24:40") still belong to the day before.
/// The timetable's day: the Athens date, before 04:00 still the day before. When it changes, the
/// last runs found are yesterday's.
DateTime serviceDay(DateTime utc) {
  final w = athensWall(utc); // the wall clock: the night the clocks change, 04:00 is still 04:00
  return DateTime.utc(w.year, w.month, w.hour < 4 ? w.day - 1 : w.day);
}

int serviceNowS(DateTime utc) {
  final w = athensWall(utc);
  final s = w.hour * 3600 + w.minute * 60 + w.second;
  return w.hour < 4 ? s + 86400 : s;
}

/// The last run of today's timetable of each way home, when it passes the boarding stop (s since
/// Athens midnight, past 24 h after it); the earliest first. A line without a timetable is left out.
List<HomeLast> lastHome(List<HomeBoard> boards, Map<String, Map<String, dynamic>> schedules, Map<String, LineStatic> statics) {
  final out = <HomeLast>[];
  for (final b in boards) {
    final j = schedules[b.line], st = statics[b.line];
    if (j == null || st == null) continue;
    final r = lastRun(j, st, b.variant, b.i);
    if (r != null) out.add((line: b.line, stop: b.stop, atS: r.atStopS));
  }
  return out..sort((a, b) => a.atS.compareTo(b.atS));
}

/// [atS] of the timetable day that [nowUtc] is in, as a moment: «24:40» on the evening of the 29th is
/// 00:40 on the 30th, also when asked at 00:10 on the 30th.
DateTime serviceMoment(int atS, DateTime nowUtc) {
  final d = serviceDay(nowUtc);
  return athensDayUtc(DateTime.utc(d.year, d.month, d.day, 12), atS);
}
