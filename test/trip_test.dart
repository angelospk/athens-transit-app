import 'package:athens_transit/core/geo.dart';
import 'package:athens_transit/core/models.dart';
import 'package:athens_transit/core/trip.dart';
import 'package:flutter_test/flutter_test.dart';

// Port of the web planner's tests (athens-transit-map, tests/trip.test.ts).

// ~111 m per 0.001° of latitude: stops on a north-south street, 0.001° apart.
Pt at(int k) => (38 + k * 0.001, 23.7);

TripIndex tripIndex(Map<String, Map<String, List<int>>> lines, [List<String>? names]) {
  var n = 0;
  for (final vs in lines.values) {
    for (final seq in vs.values) {
      for (final k in seq) {
        if (k + 1 > n) n = k + 1;
      }
    }
  }
  return TripIndex(
    v: 't',
    s: [
      for (var k = 0; k < n; k++)
        (names != null && k < names.length ? names[k] : 'S$k', at(k).$1, at(k).$2),
    ],
    l: lines,
  );
}

void main() {
  group('findTrips', () {
    final ix = tripIndex({
      'A': {
        'up': [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10],
        'down': [10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0],
      },
      'B': {
        'up': [0, 1, 2, 3, 4, 5],
      }, // never near stop 10
      'C': {
        'x': [20, 21, 22, 10, 9],
      }, // reaches stop 10 from elsewhere
    });

    test('finds the variants that pass near the origin and then near the destination', () {
      final r = findTrips(ix, [at(0)], [at(10)], 300);
      expect(r.map((t) => t.line), ['A']);
      expect(r[0].variants.map((v) => v.id), ['up']);
      expect((r[0].variants[0].from, r[0].variants[0].to), (0, 10));
    });

    test('boards at the nearest stop, not the first one in reach, and alights at the nearest one', () {
      final t = findTrips(ix, [at(2)], [at(8)], 300).single;
      expect(t.variants[0].id, 'up');
      expect((t.variants[0].from, t.variants[0].to), (2, 8));
      expect(t.variants[0].walk, 0);
      expect(t.variants[0].stops, 6);
    });

    test('finds nothing when the ends are too close to need a bus', () {
      expect(findTrips(ix, [at(0)], [at(1)], 300), isEmpty);
    });

    test("uses a line's repeated stop at the occurrence that gives a trip (loops)", () {
      // Starts and passes 0 again.
      final loop = tripIndex({
        'L': {
          'v': [0, 1, 2, 3, 4, 5, 6, 0, 7, 8, 9, 10],
        },
      });
      final t = findTrips(loop, [at(0)], [at(10)], 50).single;
      // The later boarding: fewer stops.
      expect((t.variants[0].i, t.variants[0].j, t.variants[0].stops), (7, 11, 4));
    });

    test('ranks lines by estimated time (walking and riding), then stops, then id, deterministically', () {
      final two = tripIndex({
        'Z': {
          'v': [0, 5, 10],
        },
        'Y': {
          'v': [0, 10],
        },
        'X': {
          'v': [1, 10],
        },
      });
      expect(findTrips(two, [at(0)], [at(10)], 300).map((t) => t.line), ['Y', 'Z', 'X']);
    });

    test('estimates minutes: walking at 4.5 km/h on streets a third longer than the straight line, riding at 15 km/h', () {
      final t = findTrips(ix, [at(0)], [at(10)], 300).single;
      expect(t.min, closeTo(1110 / 250, 0.5)); // 1.1 km on the bus, no walking
      // 88 m west of stop 0.
      final w = findTrips(ix, [(38.0, 23.701)], [at(10)], 300).single;
      expect(w.min - t.min, closeTo(88 * 1.3 / 75, 0.5));
    });

    test('prefers a longer walk that saves a long ride', () {
      // V reaches stop 10 from stop 0 the long way round; W boards 220 m away and goes straight there.
      final long = tripIndex({
        'V': {
          'v': [0, 30, 31, 32, 33, 10],
        },
        'W': {
          'v': [2, 10],
        },
      });
      long.s[30] = ('F1', 38.02, 23.75);
      long.s[31] = ('F2', 38.04, 23.75);
      long.s[32] = ('F3', 38.04, 23.70);
      long.s[33] = ('F4', 38.02, 23.70);
      expect(findTrips(long, [at(0)], [at(10)], 300).map((t) => t.line), ['W', 'V']);
    });

    test('leaves out lines missing from the current line list', () {
      expect(findTrips(ix, [at(0)], [at(10)], 300, {'B'}), isEmpty);
    });
  });

  group('places and searchPlaces', () {
    // Two ΕΚΚΛΗΣΙΑ stops 5 km apart; three ΑΜΠΕΛΟΚΗΠΟΙ stops each 500 m apart (a chain).
    final ix = TripIndex(v: 't', s: [
      ('ΕΚΚΛΗΣΙΑ', 38.0, 23.7),
      ('ΕΚΚΛΗΣΙΑ', 38.045, 23.7),
      ('ΑΜΠΕΛΟΚΗΠΟΙ', 37.98, 23.76),
      ('ΑΜΠΕΛΟΚΗΠΟΙ', 37.9845, 23.76),
      ('ΑΜΠΕΛΟΚΗΠΟΙ', 37.989, 23.76),
      ('ΣΤ. ΑΜΠΕΛΟΚΗΠΟΙ', 37.987, 23.757),
      ('ΔΙΑΣΤΑΥΡΩΣΗ', 38.0, 23.8),
      ('ΠΛ. ΑΓ. ΓΕΩΡΓΙΟΥ', 38.0, 23.9),
    ], l: {
      '040': {
        'a': [0, 2, 3],
      },
      '550': {
        'a': [1, 4, 5],
      },
      'Α1': {
        'a': [6, 7],
      },
    });
    final ps = places(ix);

    test('keeps same-name stops far apart as separate places, with their lines as a hint', () {
      final e = ps.where((p) => p.label == 'ΕΚΚΛΗΣΙΑ');
      expect(e.map((p) => p.lines), [
        ['040'],
        ['550'],
      ]);
    });

    test("does not chain clusters: a stop is grouped only near the cluster's first stop", () {
      final a = ps.where((p) => p.label == 'ΑΜΠΕΛΟΚΗΠΟΙ');
      expect(a.map((p) => p.pts.length), [2, 1]);
    });

    test('gives the same places for any stop order', () {
      final rev = TripIndex(v: 't', s: ix.s.reversed.toList(), l: {
        'x': {
          'a': [for (var k = 0; k < ix.s.length; k++) ix.s.length - 1 - k],
        },
      });
      String shape(List<Place> list) =>
          ([for (final p in list) '${p.label} ${p.pts.length}']..sort()).join('|');
      expect(shape(places(rev)), shape(ps));
    });

    test('sorts a place lines as numbers, not as text', () {
      final one = TripIndex(v: 't', s: [('S', 38.0, 23.7)], l: {
        '10': {
          'a': [0],
        },
        '2': {
          'a': [0],
        },
        'A2': {
          'a': [0],
        },
        'A1': {
          'a': [0],
        },
        '040': {
          'a': [0],
        },
      });
      expect(places(one).single.lines, ['2', '10', '040', 'A1', 'A2']);
    });

    test('matches at word starts, ignoring case, accents and final sigma', () {
      List<String> labels(String q) => [for (final p in searchPlaces(ps, q)) p.label];
      expect(labels('Αμπελόκηποι')[0], 'ΑΜΠΕΛΟΚΗΠΟΙ');
      expect(labels('αμπελ'), contains('ΣΤ. ΑΜΠΕΛΟΚΗΠΟΙ'));
      expect(labels('ταυρ'), isEmpty); // not ΔΙΑΣΤΑΥΡΩΣΗ
      expect(labels('γεωργιου'), ['ΠΛ. ΑΓ. ΓΕΩΡΓΙΟΥ']);
      expect(labels('αγ. γεωρ'), ['ΠΛ. ΑΓ. ΓΕΩΡΓΙΟΥ']);
      expect(labels('εκκλησιας'), isEmpty);
      expect(labels('  '), isEmpty);
    });
  });

  group('termini', () {
    final names = ['ΑΡΧΗ', 'ΜΕΣΗ', 'ΤΕΡΜΑ', 'ΑΛΛΟ', 'ΑΛΛΟΥ'];
    final ix = tripIndex({
      // Two variants end at ΤΕΡΜΑ.
      'A': {
        'up': [0, 1, 2],
        'up2': [0, 1, 2],
        'other': [0, 1, 3],
      },
      'L': {
        'loop': [0, 1, 0],
      },
      'Z': {
        'gone': <int>[],
      },
    }, names);

    test('is where each direction ends, once', () {
      expect(termini(ix, 'A', ['up', 'up2', 'other']), ['ΤΕΡΜΑ', 'ΑΛΛΟ']);
    });

    test('is the first stop again for a loop', () {
      expect(termini(ix, 'L', ['loop']), ['ΑΡΧΗ']);
    });

    test('leaves out a variant or line the index does not know', () {
      expect(termini(ix, 'A', ['nope', 'up']), ['ΤΕΡΜΑ']);
      expect(termini(ix, 'Z', ['gone']), isEmpty);
      expect(termini(ix, 'Q', ['up']), isEmpty);
    });
  });

  group('boardings', () {
    // Stops 0-10 on one street; 1 and 3 share a name (two sides of a square).
    final names = ['S0', 'ΠΛΑΤΕΙΑ', 'S2', 'ΠΛΑΤΕΙΑ'];
    final ix = tripIndex({
      'A': {
        'up': [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10],
        'down': [10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0],
      },
      'B': {
        'up': [2, 3, 4, 10],
      },
      'C': {
        'up': [0, 9],
      },
    }, names);
    Boarding named(List<Boarding> list, String name) =>
        list.firstWhere((b) => b.name == name);
    String fmt(Boarding b) => b.lines
        .map((l) => '${l.line}:${l.variants.map((v) => '${v.id}/${v.i}/${v.from}').join(',')}')
        .join(' ');

    test('lists the stops near the start that reach the end, nearest first, one per name', () {
      final r = boardings(ix, [at(0)], [at(10)], 400, ['A', 'B', 'C']);
      expect([for (final b in r) (b.name, (b.walk / 10).round() * 10)],
          [('S0', 0), ('ΠΛΑΤΕΙΑ', 110), ('S2', 220)]);
    });

    test("gives each stop its lines in trip order, at the stop's position in each variant", () {
      final r = boardings(ix, [at(0)], [at(10)], 400, ['B', 'A', 'C']);
      // The nearer of the two stops of the name for A.
      expect(fmt(named(r, 'ΠΛΑΤΕΙΑ')), 'B:up/1/3 A:up/1/1');
      expect(named(r, 'S0').lines.map((l) => l.line), ['A', 'C']);
    });

    test('leaves out lines not asked for, and keeps at most max stops', () {
      expect(boardings(ix, [at(0)], [at(10)], 400, ['C']).map((b) => b.name), ['S0']);
      expect(boardings(ix, [at(0)], [at(10)], 400, ['A', 'B', 'C'], 2), hasLength(2));
    });

    test('boards a loop at the occurrence with the fewest stops to the end', () {
      final loop = tripIndex({
        'L': {
          'v': [0, 1, 2, 3, 4, 5, 6, 0, 7, 8, 9, 10],
        },
      });
      final v = boardings(loop, [at(0)], [at(10)], 50, ['L'])[0].lines[0].variants;
      expect([for (final x in v) '${x.id}/${x.i}/${x.from}'], ['v/7/0']);
    });
  });

  group('findTransfers', () {
    // A goes north from stop 0 to stop 5; B starts 44 m east of stop 5 and goes east to stop 10.
    final ix = TripIndex(v: 't', s: [
      for (var k = 0; k < 6; k++) ('N$k', 38 + k * 0.001, 23.7),
      ('E0', 38.005, 23.7005),
      ('E1', 38.005, 23.702),
      ('E2', 38.005, 23.704),
      ('E3', 38.005, 23.706),
      ('E4', 38.005, 23.708),
    ], l: {
      'A': {
        'up': [0, 1, 2, 3, 4, 5],
      },
      'B': {
        'e': [6, 7, 8, 9, 10],
      },
      'C': {
        'e': [0, 1],
      },
    });
    const end = (38.005, 23.708);

    test('changes once, walking to a nearby stop of the second line', () {
      final r = findTransfers(ix, [at(0)], [end], 300).first;
      expect(r.legs.map((l) => l.line), ['A', 'B']);
      expect((r.legs[0].id, r.legs[0].from, r.legs[0].to), ('up', 0, 5));
      expect((r.legs[1].id, r.legs[1].from, r.legs[1].to), ('e', 6, 10));
      expect(r.xfer, greaterThan(30));
      expect(r.xfer, lessThan(60));
      expect(r.min, greaterThan(5)); // a change costs a wait
    });

    test('finds no change when the second line is out of walking reach, or the trip needs none', () {
      final far = TripIndex(v: 't', s: [
        for (var k = 0; k < ix.s.length; k++)
          k >= 6
              ? (ix.s[k].$1, ix.s[k].$2 - 0.004, ix.s[k].$3 + 0.003)
              : ix.s[k],
      ], l: ix.l);
      expect(findTransfers(far, [at(0)], [(38.001, 23.711)], 300), isEmpty);
      expect(
          findTransfers(ix, [at(0)], [at(5)], 300)
              .every((r) => r.legs[0].line != r.legs[1].line),
          isTrue);
    });

    test('gives an alert the first line of a change, as a trip that ends at the change', () {
      final r = findTransfers(ix, [at(0)], [end], 300).first;
      final t = legTrip(r.legs[0]);
      expect((t.line, t.stops), ('A', 5));
      final v = t.variants.single;
      expect((v.id, v.i, v.j, v.from, v.to), ('up', 0, 5, 0, 5));
    });

    test('leaves out lines missing from the current line list', () {
      expect(findTransfers(ix, [at(0)], [end], 300, {'A'}), isEmpty);
    });
  });

  group('metro places', () {
    final data = <MetroStation>[
      (name: 'ΣΥΝΤΑΓΜΑ', lat: 37.975, lon: 23.735, lines: ['M2', 'M3']),
      (name: 'ΑΚΡΟΠΟΛΗ', lat: 37.969, lon: 23.729, lines: ['M2']),
      (name: 'ΖΑΠΠΕΙΟ', lat: 37.970, lon: 23.738, lines: ['T6']),
    ];

    test('are stations to start or end at, with their lines', () {
      final ps = metroPlaces(data);
      expect(ps.map((p) => p.label), ['ΣΥΝΤΑΓΜΑ', 'ΑΚΡΟΠΟΛΗ', 'ΖΑΠΠΕΙΟ']);
      expect(ps[0].kind, PlaceKind.metro);
      expect(ps[0].lines, ['M2', 'M3']);
      expect(ps[0].pts, [(37.975, 23.735)]);
    });

    test('come before a bus stop place of the same name', () {
      final bus = Place(
          label: 'ΣΥΝΤΑΓΜΑ',
          pts: [(37.976, 23.734)],
          lines: ['1', '2', '3', '4'],
          kind: PlaceKind.stop);
      final r = searchPlaces([bus, ...metroPlaces(data)], 'συνταγμα');
      expect(r.first.kind, PlaceKind.metro);
    });

    test('any metro station: every metro and ISAP station, not the tram', () {
      final any = anyMetro(data);
      expect(any.kind, PlaceKind.metroAny);
      expect(any.pts, [(37.975, 23.735), (37.969, 23.729)]);
    });

    test('finds a metro or tram line that joins stations near both ends', () {
      final r = metroDirect(data, [(37.9752, 23.7352)], [(37.9692, 23.7292)], 300);
      expect(r?.line, 'M2');
      expect(r?.from, 'ΣΥΝΤΑΓΜΑ');
      expect(r?.to, 'ΑΚΡΟΠΟΛΗ');
      // ΖΑΠΠΕΙΟ: T6 only, no shared line.
      expect(metroDirect(data, [(37.975, 23.735)], [(37.970, 23.738)], 300), isNull);
      // No station near the start.
      expect(metroDirect(data, [(37.99, 23.70)], [(37.969, 23.729)], 300), isNull);
    });

    test('names the metro station nearest a point, with its distance', () {
      expect(nearestStation(data, (37.9691, 23.7291))?.name, 'ΑΚΡΟΠΟΛΗ');
      expect(nearestStation(data, (37.9691, 23.7291))!.d, lessThan(20));
      expect(nearestStation(const [], (37.97, 23.73)), isNull);
    });
  });

  test('centre of a set of points', () {
    final c = centre([(38.0, 23.7), (38.002, 23.702)]);
    expect(c.$1, closeTo(38.001, 1e-9));
    expect(c.$2, closeTo(23.701, 1e-9));
  });
}
