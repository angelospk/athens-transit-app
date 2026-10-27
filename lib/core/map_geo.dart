// GeoJSON for the map's line layers, as on the web (layers.ts). Contract shapes are [lat, lon];
// GeoJSON wants [lon, lat].

import 'models.dart';

typedef Geo = Map<String, dynamic>;
typedef DrawnLine = ({String line, String color, LineStatic st, Set<String>? only});

Geo _fc(List<Object> features) => {'type': 'FeatureCollection', 'features': features};

// One LineString per variant (only the `only` variants when given), in travel direction: the map's
// arrows follow the order of the points.
Geo routesGeo(Iterable<DrawnLine> lines) => _fc([
      for (final l in lines)
        for (final e in l.st.variants.entries)
          if (l.only == null || l.only!.contains(e.key))
            {
              'type': 'Feature',
              'properties': {'line': l.line, 'variant': e.key, 'color': l.color},
              'geometry': {
                'type': 'LineString',
                'coordinates': [for (final p in e.value.shape) [p.$2, p.$1]],
              },
            },
    ]);

// The stops of one variant in order, of some variants, or of every variant, each stop once.
Geo lineStopsGeo(LineStatic st, String color, {String? variant, Iterable<String>? variants}) {
  final vs = variant != null ? [variant] : variants ?? st.variants.keys;
  final ids = {for (final v in vs) ...?st.variants[v]?.stops};
  return _fc([
    for (final id in ids)
      if (st.stops[id] case final s?)
        {
          'type': 'Feature',
          'id': 'rs|$id', // the map's tap finds the stop by it
          'properties': {'id': id, 'name': s.name, 'color': color},
          'geometry': {'type': 'Point', 'coordinates': [s.lon, s.lat]},
        },
  ]);
}

bool isTram(String line) => line.startsWith('T');

// metro.json: tracks and stations. `tram` is true for tram tracks and for stations only the tram
// serves, so the map can hide metro and tram apart; a shared station counts as a metro station.
Geo metroGeo(Map<String, dynamic> j, {required String Function(String) name}) {
  final lines = [for (final l in j['lines'] as List) l as Map<String, dynamic>];
  final colors = {for (final l in lines) l['id']: l['color']};
  return _fc([
    for (final l in lines)
      for (final p in l['paths'] as List)
        {
          'type': 'Feature',
          'properties': {'color': l['color'], 'tram': isTram(l['id'] as String)},
          'geometry': {'type': 'LineString', 'coordinates': p},
        },
    for (final (i, s) in (j['stations'] as List).indexed)
      () {
        final ids = [for (final x in s['lines'] as List) x as String];
        final first = ids.where((x) => !isTram(x)).firstOrNull ?? ids.firstOrNull;
        return {
          'type': 'Feature',
          'id': 'm$i',
          'properties': {'name': name(s['name'] as String), 'color': colors[first] ?? '#43474E', 'tram': ids.every(isTram)},
          'geometry': {'type': 'Point', 'coordinates': [s['lon'], s['lat']]},
        };
      }(),
  ]);
}
