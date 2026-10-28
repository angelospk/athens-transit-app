// GeoJSON for the map's line layers, as on the web (layers.ts). Contract shapes are [lat, lon];
// GeoJSON wants [lon, lat].

import 'models.dart';
import 'rail.dart';

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

// Suburban rail: each line once (dashed on the map) and each station once, in the colour of its first
// line; a station's feature id ("r|<railway.gov.gr id>") is what a tap finds it by.
Geo railGeo(Suburban sub, {required String Function(String) name}) => _fc([
      for (final c in sub.corridors.values)
        {
          'type': 'Feature',
          'properties': {'color': c.color},
          'geometry': {'type': 'LineString', 'coordinates': [for (final p in c.path) [p.$2, p.$1]]},
        },
      for (final s in sub.stations.values)
        {
          'type': 'Feature',
          'id': 'r|${s.id}',
          'properties': {'name': name(s.name), 'color': sub.corridors[s.corridors.first]?.color ?? '#43474E'},
          'geometry': {'type': 'Point', 'coordinates': [s.lon, s.lat]},
        },
    ]);
