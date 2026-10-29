import 'package:athens_transit/core/geo.dart';
import 'package:athens_transit/core/models.dart';
import 'package:athens_transit/core/near_home.dart';
import 'package:athens_transit/core/rail.dart';
import 'package:flutter_test/flutter_test.dart';

// 0.001° of latitude is ~111.2 m.
const lat0 = 37.98, lon0 = 23.73;
Pt north(double m) => (lat0 + m / 111195, lon0);
const me = (lat0, lon0);

TripIndex ixOf(List<(String, double)> stops, Map<String, List<int>> lines) => TripIndex(
      v: 't',
      s: [for (final (name, m) in stops) (name, north(m).$1, north(m).$2)],
      l: {for (final e in lines.entries) e.key: {'v': e.value}},
    );

Station station(String name, double m, List<String> lines, {String? railId}) =>
    Station(name: name, lat: north(m).$1, lon: north(m).$2, lines: lines, railId: railId);

void main() {
  group('nearPlaces', () {
    test('bus stops and stations together, nearest first', () {
      final ix = ixOf([('Α', 300), ('Β', 100), ('Γ', 500)], {'040': [0, 1], '550': [2]});
      final got = nearPlaces(ix, [station('ΣΥΝΤΑΓΜΑ', 200, ['M2', 'M3'])], me);
      expect(got.map((p) => p.name), ['Β', 'ΣΥΝΤΑΓΜΑ', 'Α', 'Γ']);
      expect(got.map((p) => p.kind), [NearKind.bus, NearKind.metro, NearKind.bus, NearKind.bus]);
      expect(got.first.distM, closeTo(100, 2));
      expect(got.first.lines, ['040']);
      expect(got[1].lines, ['M2', 'M3']);
    });

    test('at most max places', () {
      final ix = ixOf([for (var i = 0; i < 12; i++) ('S$i', 20.0 + i * 40)], {'1': [for (var i = 0; i < 12; i++) i]});
      expect(nearPlaces(ix, const [], me, max: 8).length, 8);
    });

    test('widens the radius while fewer than `enough` places are found', () {
      final ix = ixOf([('Κοντά', 400), ('Μακριά', 1000), ('Πιο μακριά', 1100)], {'1': [0, 1, 2]});
      final got = nearPlaces(ix, const [], me, radii: const [600, 1200, 2500], enough: 3);
      expect(got.map((p) => p.name), ['Κοντά', 'Μακριά', 'Πιο μακριά']);
    });

    test('keeps the first radius when it has enough places', () {
      final ix = ixOf([('Α', 100), ('Β', 200), ('Γ', 300), ('Μακριά', 1000)], {'1': [0, 1, 2, 3]});
      expect(nearPlaces(ix, const [], me, radii: const [600, 1200], enough: 3).map((p) => p.name), ['Α', 'Β', 'Γ']);
    });

    test('nothing within the largest radius: empty', () {
      final ix = ixOf([('Μακριά', 5000)], {'1': [0]});
      expect(nearPlaces(ix, const [], me, radii: const [600, 1200]), isEmpty);
    });

    test('no trip index yet: only the stations', () {
      expect(nearPlaces(null, [station('ΟΜΟΝΟΙΑ', 300, ['M1', 'M2'])], me).map((p) => p.name), ['ΟΜΟΝΟΙΑ']);
    });

    test('kinds: tram for tram lines only, rail for a suburban station', () {
      final got = nearPlaces(null, [
        station('ΣΕΦ', 100, ['T6', 'T7']),
        station('ΦΑΛΗΡΟ', 200, ['M1', 'T6']),
        station('Αγ. Ανάργυροι', 300, ['KIATO'], railId: 'r1'),
      ], me);
      expect(got.map((p) => p.kind), [NearKind.tram, NearKind.metro, NearKind.rail]);
      expect(got.last.railId, 'r1');
    });
  });

  group('stations', () {
    test('metro.json: same-name entries close together merge, lines kept once', () {
      final got = metroStations({
        'stations': [
          {'name': 'ΟΜΟΝΟΙΑ', 'lat': 37.9841, 'lon': 23.7280, 'lines': ['M1']},
          {'name': 'ΟΜΟΝΟΙΑ', 'lat': 37.9842, 'lon': 23.7282, 'lines': ['M2', 'M1']},
          {'name': 'ΑΝΘΟΥΠΟΛΗ', 'lat': 38.0175, 'lon': 23.6904, 'lines': ['M2']},
        ],
      });
      expect(got.map((s) => s.name), ['ΟΜΟΝΟΙΑ', 'ΑΝΘΟΥΠΟΛΗ']);
      expect(got.first.lines, ['M1', 'M2']);
      expect(got.first.railId, isNull);
    });

    test('metro.json: a second name for the same station (a shared line, within 150 m) merges', () {
      final got = metroStations({
        'stations': [
          {'name': 'ΣΥΝΤΑΓΜΑ', 'lat': 37.97535, 'lon': 23.73540, 'lines': ['M2', 'M3', 'T6']},
          {'name': 'Σύνταγμα (Κέντρο)', 'lat': 37.97537, 'lon': 23.73543, 'lines': ['T6', 'M2', 'M3']},
          {'name': 'ΑΚΡΟΠΟΛΗ', 'lat': 37.96880, 'lon': 23.72960, 'lines': ['M2']},
        ],
      });
      expect(got.map((s) => s.name), ['ΣΥΝΤΑΓΜΑ', 'ΑΚΡΟΠΟΛΗ']);
      expect(got.first.lines, ['M2', 'M3', 'T6']);
    });

    test('suburban: its id, corridors once each', () {
      final sub = Suburban.fromJson({
        'corridors': <String, dynamic>{},
        'stations': [
          {'id': 'r1', 'name': 'Αγ. Ανάργυροι', 'en': 'Ag. Anargyroi', 'lat': 38.02, 'lon': 23.72, 'corridors': ['KIATO', 'PIRAIR', 'PIRAIR']},
        ],
      });
      final got = suburbanStations(sub);
      expect(got.single.railId, 'r1');
      expect(got.single.lines, ['KIATO', 'PIRAIR']);
    });
  });

  group('myLinesHere', () {
    test('the saved lines that stop there, in the stop\'s order', () {
      final p = NearPlace(kind: NearKind.bus, name: 'Α', lat: lat0, lon: lon0, distM: 50, lines: const ['040', '550', 'Α2']);
      expect(myLinesHere(p, ['Α2', '040', '999']), ['040', 'Α2']);
      expect(myLinesHere(p, const []), isEmpty);
    });

    test('a station never matches a bus line id', () {
      final p = NearPlace(kind: NearKind.metro, name: 'Σ', lat: lat0, lon: lon0, distM: 50, lines: const ['M1']);
      expect(myLinesHere(p, ['M1']), isEmpty);
    });
  });

  group('labels', () {
    test('walking minutes: 80 m a minute on streets 1.25 × the straight line, at least 1', () {
      expect(walkMin(10), 1);
      expect(walkMin(320), 5);
      expect(walkMin(640), 10);
    });

    test('distance: metres to the nearest 10 below 1 km, km with one decimal above', () {
      expect(distLabel(43), '40 μ.');
      expect(distLabel(996), '1,0 χλμ.');
      expect(distLabel(1260), '1,3 χλμ.');
    });
  });
}
