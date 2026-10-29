// «Γυρνάς σπίτι»: the direct ways home from where the user is, and the last run of each, the one that
// goes first on top («το πρώτο από τα τελευταία»).
import 'package:athens_transit/core/go_home.dart';
import 'package:athens_transit/core/models.dart';
import 'package:flutter_test/flutter_test.dart';

const lat0 = 38.0, lon0 = 23.7;
List<double> north(double m) => [lat0 + m / 111195, lon0];

LineStatic line(String id) => LineStatic.fromJson({
      'id': id,
      'variants': {
        'out': {'headsign': 'ΚΕΝΤΡΟ - ΠΡΟΑΣΤΙΟ', 'direction': 0, 'shape': [for (final m in [0.0, 4200.0]) north(m)], 'stops': ['a', 'b', 'c']},
      },
      'stops': {
        for (final (s, m) in [('a', 0.0), ('b', 3600.0), ('c', 4200.0)]) s: {'name': s.toUpperCase(), 'lat': north(m)[0], 'lon': north(m)[1]},
      },
    });

Map<String, dynamic> sched(List<String> deps) => {
      'directions': [
        {'direction': 0, 'headsign': 'ΠΡΟΑΣΤΙΟ', 'departures': [for (final t in deps) {'t': t}]},
      ],
    };

void main() {
  final ix = TripIndex(v: 't', s: [
    for (final (s, m) in [('A', 0.0), ('B', 3600.0), ('C', 4200.0)]) (s, north(m)[0], north(m)[1]),
  ], l: {
    '040': {'out': [0, 1, 2]},
    '209': {'out': [0, 1, 2]},
    'X': {'back': [2, 1, 0]}, // the other way: not home
  });
  final from = (north(50)[0], north(50)[1]);
  final home = (north(3650)[0], north(3650)[1]);

  test('the ways home: lines that ride from near here to near home, with where to board', () {
    final b = homeBoards(ix, from, home);
    expect(b.map((x) => x.line).toSet(), {'040', '209'});
    expect(b.first.stop, 'A');
    expect(b.first.i, 0);
  });

  test('the last runs home, the one that goes first on top; a line without a timetable is left out', () {
    final b = homeBoards(ix, from, home);
    final last = lastHome(b, {'040': sched(['22:00', '24:40']), '209': sched(['21:00', '23:10'])}, {'040': line('040'), '209': line('209')});
    expect(last.map((x) => (x.line, x.atS)), [('209', 23 * 3600 + 10 * 60), ('040', 24 * 3600 + 40 * 60)]);
    expect(lastHome(b, {'040': sched(['22:00'])}, {'040': line('040'), '209': line('209')}).map((x) => x.line), ['040']);
  });

  test('already home: no ways', () {
    expect(homeBoards(ix, home, home), isEmpty);
  });

  test('after midnight the night\'s last runs are still today\'s: now runs past 24 h until 04:00', () {
    // 2026-10-29 22:50 UTC = 00:50 Athens (EET, +2) on the 30th.
    expect(serviceNowS(DateTime.utc(2026, 10, 29, 22, 50)), 24 * 3600 + 50 * 60);
    // 12:00 UTC = 14:00 Athens.
    expect(serviceNowS(DateTime.utc(2026, 10, 30, 12)), 14 * 3600);
  });
}
