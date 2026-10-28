// Stops show runs that have not started yet: today's timetable at the start + the run to the stop.
import 'package:athens_transit/core/eta.dart';
import 'package:athens_transit/core/models.dart';
import 'package:flutter_test/flutter_test.dart';

const lat0 = 38.0, lon0 = 23.7;
List<double> north(double m) => [lat0 + m / 111195, lon0];

final st = LineStatic.fromJson({
  'id': 'T1',
  'variants': {
    'v1': {'headsign': 'ΝΕΚΡ. ΖΩΓΡΑΦΟΥ', 'direction': 0, 'shape': [for (final m in [0.0, 4200.0]) north(m)], 'stops': ['a', 'b', 'c']},
    'v2': {'headsign': 'Γαλάτσι', 'direction': 1, 'shape': [for (final m in [4200.0, 0.0]) north(m)], 'stops': ['c', 'b', 'a']},
  },
  'stops': {
    for (final (id, m) in [('a', 0.0), ('b', 2100.0), ('c', 4200.0)]) id: {'name': id, 'lat': north(m)[0], 'lon': north(m)[1]},
  },
});

Map<String, dynamic> sched(List<(int, String, List<String>)> dirs) => {
      'line': 'T1',
      'source': 'oasa-daily',
      'directions': [
        for (final (d, h, deps) in dirs) {'direction': d, 'headsign': h, 'departures': [for (final t in deps) {'t': t}]},
      ],
    };

void main() {
  test('the timetable direction of a variant: by headsign (folded), else the only one of its direction', () {
    final j = sched([(0, 'ΝΕΚΡ. ΖΩΓΡΑΦΟΥ', ['05:00']), (1, 'ΓΑΛΑΤΣΙ', ['06:00'])]);
    expect(departuresFor(j, st.variants['v1']!), ['05:00']);
    expect(departuresFor(j, st.variants['v2']!), ['06:00'], reason: 'Γαλάτσι = ΓΑΛΑΤΣΙ');
    final byDir = sched([(0, 'ΑΛΛΟ', ['07:00']), (1, 'ΚΑΤΙ', ['08:00'])]);
    expect(departuresFor(byDir, st.variants['v2']!), ['08:00']);
    final twoSame = sched([(1, 'Χ', ['07:00']), (1, 'Ψ', ['08:00'])]);
    expect(departuresFor(twoSame, st.variants['v2']!), isNull, reason: 'two directions 1, no headsign: unknown');
    expect(departuresFor(const {'directions': []}, st.variants['v1']!), isNull);
  });

  test('a GTFS headsign names both ends («start - via - end»): the timetable direction is the one to its end', () {
    Variant v(String h) => Variant.fromJson({'headsign': h, 'direction': 0, 'shape': [], 'stops': []});
    final j = sched([(0, 'ΝΕΟ ΨΥΧΙΚΟ', ['05:00']), (1, 'Ν. ΦΙΛΑΔΕΛΦΕΙΑ', ['05:10'])]);
    expect(departuresFor(j, v('Ν. ΦΙΛΑΔΕΛΦΕΙΑ - ΑΝΩ ΠΑΤΗΣΙΑ - ΝΕΟ ΨΥΧΙΚΟ')), ['05:00']);
    expect(departuresFor(j, v('ΝΕΟ ΨΥΧΙΚΟ - ΑΝΩ ΠΑΤΗΣΙΑ - Ν. ΦΙΛΑΔΕΛΦΕΙΑ')), ['05:10']);
    final p = sched([(0, 'ΣΥΝΤΑΓΜΑ', ['06:00']), (1, 'ΠΕΙΡΑΙΑΣ', ['06:30'])]);
    expect(departuresFor(p, v('ΣΥΝΤΑΓΜΑ - ΠΕΙΡΑΙΑΣ(ΠΡΟΣΩΡΙΝΗ ΛΟΓΩ ΕΡΓΩΝ)')), ['06:30']);
    final loop = sched([(0, 'ΑΚΑΔΗΜΙΑ (ΚΥΚΛΙΚΗ)', ['05:00'])]);
    expect(departuresFor(loop, v('ΙΛΙΟΝ - ΑΓ. ΦΑΝΟΥΡΙΟΣ - ΑΚΑΔΗΜΙΑ')), ['05:00']);
  });

  test('a run that has not started reaches the stop at departure + distance / speed', () {
    // 10:00 now (36000 s after Athens midnight). b is 2100 m from the start: 500 s at 4.2 m/s.
    final etas = plannedEtas(['09:50', '10:05', '10:20', '11:30'], st, 'v1', 1, 36000);
    // 09:50 has started (a live bus or a missing run, not ours). 10:05 + 500 s = 800 s; 10:20 -> 1700 s.
    // 11:30 is past the hour.
    expect(etas, [800, 1700]);
  });

  test('runs before the last live bus of the direction are its own, not shown twice', () {
    expect(plannedEtas(['10:05', '10:20'], st, 'v1', 1, 36000, afterS: 900), [1700]);
    expect(plannedEtas(['10:05', '10:20'], st, 'v1', 1, 36000, afterS: 700), [1700], reason: '800 is within 2′ of the live bus at 700');
  });

  test('after midnight: "24:15" is today 00:15 + a day, so it counts in the evening before', () {
    expect(plannedEtas(['24:15'], st, 'v1', 0, 23 * 3600 + 50 * 60), [25 * 60]);
    expect(plannedEtas(['bad', ''], st, 'v1', 0, 0), isEmpty);
  });
}
