// A run that did not start (screen 14): the timetable says the bus would be at the stop about now, the
// server saw no bus leave the start for it (seen: false). The stop says so and offers another way.
import 'package:athens_transit/core/eta.dart';
import 'package:athens_transit/core/models.dart';
import 'package:flutter_test/flutter_test.dart';

const lat0 = 38.0, lon0 = 23.7;
List<double> north(double m) => [lat0 + m / 111195, lon0];

final st = LineStatic.fromJson({
  'id': 'T1',
  'variants': {
    'v1': {'headsign': 'ΑΡΧΗ - ΤΕΛΟΣ', 'direction': 0, 'shape': [for (final m in [0.0, 4200.0]) north(m)], 'stops': ['a', 'b', 'c']},
  },
  'stops': {
    for (final (id, m) in [('a', 0.0), ('b', 2100.0), ('c', 4200.0)]) id: {'name': id, 'lat': north(m)[0], 'lon': north(m)[1]},
  },
});

Map<String, dynamic> sched(List<(String, bool?)> runs) => {
      'line': 'T1',
      'source': 'oasa-daily',
      'directions': [
        {
          'direction': 0,
          'headsign': 'ΤΕΛΟΣ',
          'departures': [
            for (final (t, seen) in runs) {'t': t, 'seen': ?seen},
          ],
        },
      ],
    };

int wall(String hhmm) => int.parse(hhmm.split(':')[0]) * 3600 + int.parse(hhmm.split(':')[1]) * 60;

void main() {
  // Stop b is 2100 m from the start: 500 s at 4.2 m/s.
  test('a run that did not start and would be at the stop about now', () {
    final j = sched([('10:00', true), ('10:20', false), ('10:40', null), ('11:00', null)]);
    final got = missedRuns(j, st, 'v1', 1, wall('10:35'));
    expect(got.map((m) => m.t), ['10:20']);
    expect(got.single.etaS, wall('10:20') + 500 - wall('10:35')); // it would have passed 6′40″ ago
  });

  test('too long ago, or a run seen, or not known yet: nothing', () {
    final j = sched([('09:00', false), ('10:00', true), ('10:30', null)]);
    expect(missedRuns(j, st, 'v1', 1, wall('10:35')), isEmpty);
  });

  test('no timetable direction for the variant: nothing', () {
    expect(missedRuns(const {'directions': []}, st, 'v1', 1, wall('10:35')), isEmpty);
  });
}
