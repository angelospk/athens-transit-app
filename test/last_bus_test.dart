// «Το τελευταίο προς το σπίτι» (screen 24): Friday and Saturday evening the app suggests an alert for
// the last bus of the day that passes the home stop, coming from the far end.
import 'package:athens_transit/core/eta.dart';
import 'package:athens_transit/core/last_bus.dart';
import 'package:athens_transit/core/models.dart';
import 'package:flutter_test/flutter_test.dart';

const lat0 = 38.0, lon0 = 23.7;
List<double> north(double m) => [lat0 + m / 111195, lon0];

// Centre (a) — home (b, 3600 m from a, 600 m from c) — suburb end (c).
final st = LineStatic.fromJson({
  'id': '040',
  'variants': {
    'out': {'headsign': 'ΚΕΝΤΡΟ - ΠΡΟΑΣΤΙΟ', 'direction': 0, 'shape': [for (final m in [0.0, 4200.0]) north(m)], 'stops': ['a', 'b', 'c']},
    'in': {'headsign': 'ΠΡΟΑΣΤΙΟ - ΚΕΝΤΡΟ', 'direction': 0, 'shape': [for (final m in [4200.0, 0.0]) north(m)], 'stops': ['c', 'b', 'a']},
  },
  'stops': {
    for (final (id, m) in [('a', 0.0), ('b', 3600.0), ('c', 4200.0)]) id: {'name': id, 'lat': north(m)[0], 'lon': north(m)[1]},
  },
});

final sched = {
  'line': '040',
  'source': 'oasa-daily',
  'directions': [
    {'direction': 0, 'headsign': 'ΠΡΟΑΣΤΙΟ', 'departures': [for (final t in ['22:00', '23:30', '24:40']) {'t': t}]},
    {'direction': 1, 'headsign': 'ΚΕΝΤΡΟ', 'departures': [for (final t in ['22:10', '23:10']) {'t': t}]},
  ],
};

void main() {
  test('the last run of a direction, after midnight too, and when it passes the stop', () {
    final r = lastRun(sched, st, 'out', 1)!;
    expect(r.t, '24:40');
    expect(r.atStopS, 24 * 3600 + 40 * 60 + (3600 / 4.2).round());
    expect(lastRun(const {'directions': []}, st, 'out', 1), isNull);
  });

  test('home: the direction that comes from the far end (most of the line before the stop)', () {
    final h = homeLast(sched, st, ['b'])!;
    expect((h.variant, h.t, h.from), ('out', '24:40', 'a'));
  });

  test('the evening nudge: next Friday or Saturday at 21:00 Athens', () {
    // Wednesday 2026-10-28 12:00 UTC (14:00 Athens, EET) -> Friday 30th 21:00 Athens = 19:00 UTC.
    expect(nextNudgeUtc(DateTime.utc(2026, 10, 28, 12)), DateTime.utc(2026, 10, 30, 19));
    // Friday 21:30 Athens -> Saturday 21:00.
    expect(nextNudgeUtc(DateTime.utc(2026, 10, 30, 19, 30)), DateTime.utc(2026, 10, 31, 19));
    // Saturday 22:00 Athens -> next Friday.
    expect(nextNudgeUtc(DateTime.utc(2026, 10, 31, 20)), DateTime.utc(2026, 11, 6, 19));
  });

  test('the evening of the suggestion: Friday or Saturday from 20:00 Athens to midnight', () {
    expect(lastBusEvening(DateTime.utc(2026, 10, 30, 18, 30)), isTrue); // Fri 20:30
    expect(lastBusEvening(DateTime.utc(2026, 10, 31, 21, 30)), isTrue); // Sat 23:30
    expect(lastBusEvening(DateTime.utc(2026, 10, 30, 23, 30)), isFalse); // Sat 01:30: the timetable is Saturday's
    expect(lastBusEvening(DateTime.utc(2026, 10, 29, 19)), isFalse); // Thu 21:00
    expect(lastBusEvening(DateTime.utc(2026, 10, 31, 12)), isFalse); // Sat 14:00
  });

  test('Athens midnight in UTC, either side of the October change', () {
    expect(athensMidnightUtc(DateTime.utc(2026, 10, 28, 12)), DateTime.utc(2026, 10, 27, 22));
    expect(athensMidnightUtc(DateTime.utc(2026, 10, 20, 12)), DateTime.utc(2026, 10, 19, 21));
  });

  test('a time of the day the clock goes back: 23:00 Athens is 21:00 UTC, not 20:00', () {
    expect(athensDayUtc(DateTime.utc(2026, 10, 25, 12), 23 * 3600), DateTime.utc(2026, 10, 25, 21));
    expect(athensDayUtc(DateTime.utc(2026, 10, 25, 12), 0), DateTime.utc(2026, 10, 24, 21));
  });
}
