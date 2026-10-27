import 'package:athens_transit/core/map_geo.dart';
import 'package:athens_transit/core/models.dart';
import 'package:flutter_test/flutter_test.dart';

LineStatic twoWay() => LineStatic.fromJson({
      'id': '040',
      'variants': {
        'a': {
          'headsign': 'ΣΥΝΤΑΓΜΑ',
          'shape': [
            [37.90, 23.70],
            [37.91, 23.71],
          ],
          'stops': ['s1', 's2', 'gone'],
        },
        'b': {
          'headsign': 'ΠΕΙΡΑΙΑΣ',
          'shape': [
            [37.91, 23.71],
            [37.90, 23.70],
          ],
          'stops': ['s2', 's1', 's3'],
        },
      },
      'stops': {
        's1': {'name': 'ΕΝΑ', 'lat': 37.90, 'lon': 23.70},
        's2': {'name': 'ΔΥΟ', 'lat': 37.91, 'lon': 23.71},
        's3': {'name': 'ΤΡΙΑ', 'lat': 37.92, 'lon': 23.72},
      },
    });

List<Map<String, dynamic>> feats(Map<String, dynamic> fc) => [for (final f in fc['features'] as List) f as Map<String, dynamic>];

void main() {
  group('routesGeo', () {
    test('one LineString per variant, [lon, lat], with line, variant and colour', () {
      final fc = routesGeo([(line: '040', color: '#0072B2', st: twoWay(), only: null)]);
      final f = feats(fc);
      expect(fc['type'], 'FeatureCollection');
      expect(f.map((x) => x['properties']['variant']), ['a', 'b']);
      expect(f.first['properties'], {'line': '040', 'variant': 'a', 'color': '#0072B2'});
      expect(f.first['geometry'], {
        'type': 'LineString',
        'coordinates': [
          [23.70, 37.90],
          [23.71, 37.91],
        ],
      });
    });

    test('only keeps the given variants', () {
      final f = feats(routesGeo([(line: '040', color: '#000000', st: twoWay(), only: {'b'})]));
      expect(f.map((x) => x['properties']['variant']), ['b']);
    });
  });

  group('lineStopsGeo', () {
    test('every variant: each known stop once, unknown ids skipped', () {
      final f = feats(lineStopsGeo(twoWay(), '#0072B2'));
      expect(f.map((x) => x['properties']['id']), ['s1', 's2', 's3']);
      expect(f.first['properties'], {'id': 's1', 'name': 'ΕΝΑ', 'color': '#0072B2'});
      expect(f.first['geometry'], {'type': 'Point', 'coordinates': [23.70, 37.90]});
    });

    test('one variant: its stops in order', () {
      final f = feats(lineStopsGeo(twoWay(), '#0072B2', variant: 'b'));
      expect(f.map((x) => x['properties']['id']), ['s2', 's1', 's3']);
    });
  });

  group('metroGeo', () {
    final j = {
      'lines': [
        {'id': 'M1', 'color': '#00A651', 'paths': [[[23.7, 37.9], [23.8, 38.0]]]},
        {'id': 'T6', 'color': '#F6A01A', 'paths': [[[23.6, 37.9], [23.7, 37.9]]]},
      ],
      'stations': [
        {'name': 'ΦΑΛΗΡΟ', 'lat': 37.94, 'lon': 23.66, 'lines': ['T6']},
        {'name': 'ΣΥΝΤΑΓΜΑ', 'lat': 37.97, 'lon': 23.73, 'lines': ['M1', 'T6']},
      ],
    };

    test('tracks and stations carry tram: true only for tram-only things', () {
      final f = feats(metroGeo(j, name: (s) => s));
      final tracks = f.where((x) => x['geometry']['type'] == 'LineString').toList();
      final stations = f.where((x) => x['geometry']['type'] == 'Point').toList();
      expect(tracks.map((x) => x['properties']['tram']), [false, true]);
      expect(stations.map((x) => x['properties']['tram']), [true, false]); // a shared station is a metro station
      expect(stations.last['properties']['color'], '#00A651');
      expect(stations.first['geometry'], {'type': 'Point', 'coordinates': [23.66, 37.94]});
    });
  });
}
