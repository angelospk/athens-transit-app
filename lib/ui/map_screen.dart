// Screens 1 and 3 · Χάρτης / Μόνο οι γραμμές μου. Every vehicle from the snapshot tiles of the view
// (contract rev 5), or only the user's lines from /v1/lines; buses glide along their `path` between
// updates. The sheet shows the nearest saved stop, or, with "only my lines", where those lines are now.

import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

import '../core/geo.dart';
import '../core/models.dart';
import '../core/nearby.dart';
import '../data/locate.dart';
import '../data/store.dart';
import 'search.dart';
import 'stop_screen.dart';
import 'theme.dart';
import 'vehicle_screen.dart';
import 'widgets.dart';

const _style = 'https://tiles.openfreemap.org/styles/';
const _box = (s: 37.5, w: 22.9, n: 38.5, e: 24.5); // tiles exist only here

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});
  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  MapLibreMapController? _map;
  bool _styled = false;
  final _tiles = <String, List<Vehicle>>{}; // "z/x/y" → vehicles
  Set<String> _want = {};
  int _z = 13;
  Timer? _refresh, _glide;
  Pt? _me;
  TripIndex? _ix;
  String? _styleFor;

  @override
  void initState() {
    super.initState();
    _glide = Timer.periodic(const Duration(seconds: 2), (_) => _draw());
    _refresh = Timer.periodic(const Duration(seconds: 30), (_) => _loadTiles(force: true));
    myPosition().then((p) {
      if (!mounted || p == null) return;
      setState(() => _me = p);
      _map?.animateCamera(CameraUpdate.newLatLngZoom(LatLng(p.$1, p.$2), 15));
    });
  }

  @override
  void dispose() {
    _refresh?.cancel();
    _glide?.cancel();
    super.dispose();
  }

  Future<void> _onStyle() async {
    final m = _map!;
    final api = Deps.of(context).api;
    _styled = false;
    await m.addGeoJsonSource('metro', _empty);
    await m.addLineLayer('metro', 'metro-track',
        const LineLayerProperties(lineColor: ['get', 'color'], lineWidth: ['interpolate', ['linear'], ['zoom'], 10, 2, 15, 5], lineOpacity: .75),
        filter: ['==', ['geometry-type'], 'LineString'], enableInteraction: false);
    await m.addCircleLayer('metro', 'metro-station',
        const CircleLayerProperties(circleRadius: ['interpolate', ['linear'], ['zoom'], 10, 3, 15, 7], circleColor: '#FFFFFF', circleStrokeColor: ['get', 'color'], circleStrokeWidth: 3),
        filter: ['==', ['geometry-type'], 'Point']);
    await m.addSymbolLayer('metro', 'metro-name',
        const SymbolLayerProperties(textField: ['get', 'name'], textFont: ['Noto Sans Regular'], textSize: 11, textOffset: [0, 1.2], textColor: '#43474E', textHaloColor: '#FFFFFF', textHaloWidth: 1.5),
        filter: ['==', ['geometry-type'], 'Point'], minzoom: 13, enableInteraction: false);
    await m.addGeoJsonSource('stops', _empty);
    await m.addCircleLayer('stops', 'stop-dot',
        const CircleLayerProperties(circleRadius: 5, circleColor: '#FFFFFF', circleStrokeColor: '#43474E', circleStrokeWidth: 2),
        minzoom: 15);
    await m.addGeoJsonSource('vehicles', _empty);
    await m.addCircleLayer('vehicles', 'veh-dot',
        const CircleLayerProperties(
          circleRadius: ['interpolate', ['linear'], ['zoom'], 10, 3, 13, 7, 16, 11],
          circleColor: ['get', 'bg'],
          circleStrokeColor: '#FFFFFF',
          circleStrokeWidth: 2,
        ));
    await m.addSymbolLayer('vehicles', 'veh-label',
        const SymbolLayerProperties(
          textField: ['get', 'line'],
          textFont: ['Noto Sans Bold'],
          textSize: ['interpolate', ['linear'], ['zoom'], 13, 8, 16, 11],
          textColor: ['get', 'fg'],
          textAllowOverlap: true,
          textIgnorePlacement: true,
        ),
        minzoom: 13);
    _styled = true;
    api.metro().then((j) => m.setGeoJsonSource('metro', _metroGeo(j))).catchError((_) {});
    _ix ??= await api.trips();
    await m.setGeoJsonSource('stops', {
      'type': 'FeatureCollection',
      'features': [
        for (final (i, s) in _ix!.s.indexed)
          {
            'type': 'Feature',
            'id': 's$i',
            'properties': {'i': i},
            'geometry': {'type': 'Point', 'coordinates': [s.$3, s.$2]},
          }
      ],
    });
    await _loadTiles(force: true);
  }

  static Map<String, dynamic> _metroGeo(Map<String, dynamic> j) {
    final colors = {for (final l in j['lines'] as List) l['id']: l['color']};
    return {
      'type': 'FeatureCollection',
      'features': [
        for (final l in j['lines'] as List)
          for (final p in l['paths'] as List)
            {'type': 'Feature', 'properties': {'color': l['color']}, 'geometry': {'type': 'LineString', 'coordinates': p}},
        for (final (i, s) in (j['stations'] as List).indexed)
          {
            'type': 'Feature',
            'id': 'm$i',
            'properties': {'name': titleCase(s['name'] as String), 'color': colors[(s['lines'] as List).first] ?? '#43474E'},
            'geometry': {'type': 'Point', 'coordinates': [s['lon'], s['lat']]},
          },
      ],
    };
  }

  static const _empty = {'type': 'FeatureCollection', 'features': <Object>[]};

  // Tile set of the view, padded by ~300 m and clamped to the box (contract rule 1).
  Future<void> _loadTiles({bool force = false}) async {
    final m = _map;
    if (m == null || !_styled || Deps.of(context).store.onlyMine) {
      _draw();
      return;
    }
    final api = Deps.of(context).api;
    final b = await m.getVisibleRegion();
    final zoom = m.cameraPosition?.zoom ?? 13;
    final z = zoom >= 13 ? 13 : 9;
    if (z != _z) _tiles.clear();
    _z = z;
    const pad = 0.003;
    final s = max(b.southwest.latitude - pad, _box.s), n = min(b.northeast.latitude + pad, _box.n);
    final w = max(b.southwest.longitude - pad, _box.w), e = min(b.northeast.longitude + pad, _box.e);
    if (s >= n || w >= e) return;
    final (x0, y0) = _tile(n, w, z);
    final (x1, y1) = _tile(s, e, z);
    final want = {for (var x = x0; x <= x1; x++) for (var y = y0; y <= y1; y++) '$z/$x/$y'};
    if (want.length > 40) return; // zoomed far out at z 13: wait for the next move
    _tiles.removeWhere((k, _) => !want.contains(k));
    _want = want;
    await Future.wait([
      for (final k in want)
        if (force || !_tiles.containsKey(k))
          () async {
            final p = k.split('/').map(int.parse).toList();
            try {
              final t = await api.tile(p[0], p[1], p[2]);
              if (_want.contains(k)) _tiles[k] = t.vehicles;
            } catch (_) {/* kept until the next refresh */}
          }(),
    ]);
    _draw();
  }

  (int, int) _tile(double lat, double lon, int z) {
    final n = 1 << z;
    final r = lat * pi / 180;
    return (((lon + 180) / 360 * n).floor(), ((1 - log(tan(r) + 1 / cos(r)) / pi) / 2 * n).floor());
  }

  // Where a vehicle is now: along `path` at its speed since the fix, stopping at the path's end.
  Pt _glidePos(Vehicle v, int now) {
    final path = v.path;
    final sp = v.speed;
    if (path == null || path.length < 2 || sp == null || sp <= 0) return (v.lat, v.lon);
    final s = min(sp * max(0, now - v.positionAt), shapeLength(path));
    return pointAt(path, s);
  }

  List<Vehicle> _vehicles(AppStore store) {
    final live = Deps.of(context).live;
    if (store.onlyMine) {
      return [
        for (final l in store.myLines)
          if (!store.hiddenLines.contains(l)) ...?live.lives[l]?.vehicles.map((v) => v.line == null ? _withLine(v, l) : v),
      ];
    }
    final seen = <String, Vehicle>{};
    for (final list in _tiles.values) {
      for (final v in list) {
        final o = seen[v.id];
        if (o == null || v.positionAt > o.positionAt) seen[v.id] = v;
      }
    }
    return seen.values.toList();
  }

  Vehicle _withLine(Vehicle v, String line) => Vehicle.fromJson({
        'id': v.id, 'line': line, 'lat': v.lat, 'lon': v.lon, 'position_at': v.positionAt, 'variant': v.variant,
        'delay_s': v.delayS, 'speed': v.speed, 'next_stop_id': v.nextStopId, 'trip_id': v.tripId,
        'path': [for (final p in v.path ?? const <Pt>[]) [p.$1, p.$2]],
      });

  Future<void> _draw() async {
    final m = _map;
    if (m == null || !_styled || !mounted) return;
    final store = Deps.of(context).store;
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final features = <Object>[];
    for (final v in _vehicles(store)) {
      final line = v.line ?? '';
      final mine = store.myLines.contains(line);
      final c = mine ? lineColor(store, line) : const LineColor(Color(0xFF5B5F66), Colors.white);
      final p = _glidePos(v, now);
      features.add({
        'type': 'Feature',
        'id': 'v|$line|${v.id}',
        'properties': {'line': line, 'bg': hex(c.bg), 'fg': hex(c.fg)},
        'geometry': {'type': 'Point', 'coordinates': [p.$2, p.$1]},
      });
    }
    await m.setGeoJsonSource('vehicles', {'type': 'FeatureCollection', 'features': features});
  }

  void _tap(Point<double> point, LatLng at, String id, String layer, Annotation? annotation) {
    if (id.startsWith('v|')) {
      final p = id.split('|');
      Navigator.push(context, MaterialPageRoute(builder: (_) => VehicleScreen(line: p[1], vehicleId: p[2])));
    } else if (id.startsWith('s') && _ix != null) {
      final i = int.tryParse(id.substring(1));
      if (i == null || i >= _ix!.s.length) return;
      final s = _ix!.s[i];
      
      Navigator.push(context, MaterialPageRoute(builder: (_) => StopScreen(stop: StopRef(name: s.$1, lat: s.$2, lon: s.$3, lines: linesAt(_ix!, s.$1, s.$2, s.$3)))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = Deps.of(context);
    final t = context.tones;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final style = '$_style${dark ? 'dark' : 'positron'}';
    if (_styleFor != null && _styleFor != style) _styled = false;
    _styleFor = style;
    final start = _me ?? athensCentre;
    return ListenableBuilder(
      listenable: Listenable.merge([d.store, d.live]),
      builder: (context, _) {
        _draw();
        return Stack(children: [
          MapLibreMap(
            styleString: style,
            initialCameraPosition: CameraPosition(target: LatLng(start.$1, start.$2), zoom: 14),
            myLocationEnabled: _me != null,
            trackCameraPosition: true,
            compassEnabled: false,
            attributionButtonPosition: AttributionButtonPosition.bottomLeft,
            attributionButtonMargins: const Point(8, 330),
            onMapCreated: (c) {
              _map = c;
              c.onFeatureTapped.add(_tap);
            },
            onStyleLoadedCallback: _onStyle,
            onCameraIdle: _loadTiles,
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                SearchField(ix: _ix),
                const SizedBox(height: 10),
                _chips(context, d.store, t),
              ]),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.end, children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(0, 0, 16, 12),
                child: FloatingActionButton(
                  heroTag: 'locate',
                  tooltip: 'Η θέση μου',
                  backgroundColor: t.ground,
                  foregroundColor: const Color(0xFF1A73E8),
                  onPressed: () async {
                    final p = await myPosition();
                    if (p == null) return;
                    setState(() => _me = p);
                    _map?.animateCamera(CameraUpdate.newLatLngZoom(LatLng(p.$1, p.$2), 15));
                  },
                  child: const Icon(Icons.my_location),
                ),
              ),
              d.store.onlyMine ? _MyLinesSheet(me: _me) : _NearSheet(me: _me, ix: _ix),
            ]),
          ),
        ]);
      },
    );
  }

  Widget _chips(BuildContext context, AppStore store, Tones t) {
    final chips = <Widget>[
      FilterChip(
        avatar: Icon(store.onlyMine ? Icons.star : Icons.star_outline, size: 18),
        label: const Text('Μόνο οι γραμμές μου'),
        selected: store.onlyMine,
        showCheckmark: false,
        backgroundColor: t.ground,
        onSelected: store.myLines.isEmpty
            ? null
            : (v) {
                store.setOnlyMine(v);
                if (!v) _loadTiles(force: true);
              },
      ),
      if (store.onlyMine)
        for (final l in store.myLines)
          FilterChip(
            label: Text(l, style: TextStyle(fontWeight: FontWeight.w700, color: store.hiddenLines.contains(l) ? t.muted : lineColor(store, l).fg)),
            selected: !store.hiddenLines.contains(l),
            selectedColor: lineColor(store, l).bg,
            backgroundColor: t.ground,
            showCheckmark: false,
            tooltip: store.hiddenLines.contains(l) ? 'Δείξε το $l' : 'Κρύψε το $l',
            onSelected: (_) => store.toggleHidden(l),
          ),
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(children: [for (final c in chips) Padding(padding: const EdgeInsets.only(right: 8), child: c)]),
    );
  }
}

// The nearest saved stop (or the nearest stop) with the user's lines there.
class _NearSheet extends StatelessWidget {
  const _NearSheet({required this.me, required this.ix});
  final Pt? me;
  final TripIndex? ix;

  @override
  Widget build(BuildContext context) {
    final d = Deps.of(context);
    final t = context.tones;
    final here = me;
    FavStop? fav;
    if (d.store.favs.isNotEmpty) {
      final byTime = d.store.favsByTime(DateTime.now().toUtc());
      fav = here == null ? byTime.first : (byTime..sort((a, b) => distTo(a, here.$1, here.$2).compareTo(distTo(b, here.$1, here.$2)))).first;
    }
    NearbyStop? near;
    if (fav == null && here != null && ix != null) near = nearbyStops(ix!, here, radiusM: 500, max: 1).firstOrNull;
    final name = fav?.name ?? near?.name;
    final lat = fav?.lat ?? near?.lat, lon = fav?.lon ?? near?.lon;
    final lines = fav?.lines ?? near?.lines.where(d.store.myLines.contains).toList() ?? const <String>[];
    final groups = name == null ? const [] : groupArrivals(d.live.arrivalsNear(name, lat!, lon!, only: lines)).take(3).toList();
    final dist = here == null || lat == null ? null : distM(here, (lat, lon!));
    return _Sheet(children: [
      Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
        Expanded(
          child: InkWell(
            onTap: name == null
                ? null
                : () async {
                    final ixx = ix ?? await d.api.trips();
                    if (!context.mounted) return;
                    final all = linesAt(ixx, name, lat!, lon!);
                    Navigator.push(context,
                        MaterialPageRoute(builder: (_) => StopScreen(stop: StopRef(name: name, lat: lat, lon: lon, lines: all.isEmpty ? lines : all))));
                  },
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(dist == null ? (fav?.place == Place.work ? 'Δουλειά' : 'Η στάση σου') : 'Κοντά σου · ${dist.round()} μ.',
                  style: TextStyle(fontSize: 13, color: t.muted, fontWeight: FontWeight.w500)),
              Text(name == null ? 'Διάλεξε μια στάση στον χάρτη' : titleCase(name), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
            ]),
          ),
        ),
        const LiveNote(),
      ]),
      for (final (first, then) in groups) ArrivalRow(first: first, then: then, estimate: d.live.isOffline),
      if (name != null && groups.isEmpty && lines.isNotEmpty)
        Padding(padding: const EdgeInsets.symmetric(vertical: 10), child: Text('Κανένα από ${lines.join(', ')} δεν έρχεται τώρα.', style: TextStyle(color: t.muted))),
    ]);
  }
}

// Screen 3's sheet: "Οι γραμμές μου τώρα" — buses on the road, how many are late, next at the stop.
class _MyLinesSheet extends StatelessWidget {
  const _MyLinesSheet({required this.me});
  final Pt? me;

  @override
  Widget build(BuildContext context) {
    final d = Deps.of(context);
    final t = context.tones;
    final fav = d.store.favs.isEmpty ? null : d.store.favsByTime(DateTime.now().toUtc()).first;
    final rows = <Widget>[];
    for (final l in d.store.myLines.where((l) => !d.store.hiddenLines.contains(l))) {
      final vs = d.live.lives[l]?.vehicles ?? const <Vehicle>[];
      final late = vs.where((v) => (v.delayS ?? 0) > 300).length;
      final next = fav == null ? null : d.live.arrivalsNear(fav.name, fav.lat, fav.lon, only: [l]).firstOrNull;
      rows.add(Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(children: [
          LineBadge(l),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${vs.length} ${vs.length == 1 ? 'λεωφορείο' : 'λεωφορεία'} στον δρόμο', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              Text(late == 0 ? 'όλα στην ώρα τους' : '$late ${late == 1 ? 'αργεί' : 'αργούν'} πάνω από 5′',
                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: late == 0 ? t.onTime : t.late)),
            ]),
          ),
          if (next != null && fav != null)
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text(titleCase(fav.name), style: TextStyle(fontSize: 12, color: t.muted)),
              Text(mins(next.etaS), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
            ]),
        ]),
      ));
    }
    return _Sheet(children: [
      Text('Οι γραμμές μου τώρα', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
      Text('τα άλλα λεωφορεία κρυμμένα', style: TextStyle(fontSize: 13, color: t.muted)),
      ...rows,
    ]);
  }
}

class _Sheet extends StatelessWidget {
  const _Sheet({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final t = context.tones;
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxHeight: 320),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      decoration: BoxDecoration(
        color: t.ground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: const [BoxShadow(color: Color(0x1F000000), blurRadius: 12, offset: Offset(0, -2))],
      ),
      child: SingleChildScrollView(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          Center(child: Container(width: 32, height: 4, margin: const EdgeInsets.only(bottom: 10), decoration: BoxDecoration(color: t.muted.withValues(alpha: .4), borderRadius: BorderRadius.circular(2)))),
          ...children,
        ]),
      ),
    );
  }
}
