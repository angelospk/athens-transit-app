// Screens 1 and 3 · Χάρτης / Μόνο οι γραμμές μου. Every vehicle from the snapshot tiles of the view
// (contract rev 5), or only the user's lines from /v1/lines; buses glide along their `path` between
// updates. A stop, a bus or a line opens in the sheet over the map (a drag moves it between peek, half
// and full), not on a new page; its route is drawn with arrows in travel direction, as on the web.
// With nothing open the sheet shows the nearest saved stop, or, with "only my lines", where those
// lines are now.

import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

import '../core/athens_time.dart';
import '../core/geo.dart';
import '../core/map_geo.dart';
import '../core/models.dart';
import '../core/nearby.dart';
import '../data/locate.dart';
import '../data/store.dart';
import 'line_panel.dart';
import 'map_sel.dart';
import 'rules_screen.dart';
import 'search.dart';
import 'stop_screen.dart';
import 'theme.dart';
import 'vehicle_screen.dart';
import 'widgets.dart';

const _style = 'https://tiles.openfreemap.org/styles/';
const _box = (s: 37.5, w: 22.9, n: 38.5, e: 24.5); // tiles exist only here
const _lanePx = 3.0; // each direction drawn to the right of its travel direction (two lanes), as on the web
const _peek = .14, _half = .45, _full = .92;

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
  final _sheet = DraggableScrollableController();
  double _extent = .3;
  String _routesKey = ''; // what the route layers show now: redrawn only when it changes
  int _routesGen = 0; // the newest route draw; an older one stops before writing
  String? _routesPending; // the key being drawn: the same draw is not started twice
  Pt? _followedAt; // where "follow" last centred the bus
  (bool, bool)? _rail; // metro and tram visibility applied to the map
  double _h = 700; // the map's height: the sheet's sizes are fractions of it

  @override
  void initState() {
    super.initState();
    _glide = Timer.periodic(const Duration(seconds: 2), (_) => _draw());
    _refresh = Timer.periodic(const Duration(seconds: 30), (_) => _loadTiles(force: true));
    mapSel.addListener(_onSel);
    myPosition().then((p) {
      if (!mounted || p == null) return;
      setState(() => _me = p);
      if (mapSel.value == null) _map?.animateCamera(CameraUpdate.newLatLngZoom(LatLng(p.$1, p.$2), 15));
    });
  }

  @override
  void dispose() {
    mapSel.removeListener(_onSel);
    _refresh?.cancel();
    _glide?.cancel();
    _sheet.dispose();
    super.dispose();
  }

  // A new selection: the sheet opens to half and the map moves to it.
  void _onSel() {
    if (!mounted) return;
    setState(() {});
    final s = mapSel.value;
    followBus.value = false;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_sheet.isAttached) _sheet.animateTo(s == null ? .3 : _half, duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
    });
    _routesKey = '';
    _routesPending = null;
    _routesGen++;
    _draw();
    switch (s) {
      case StopSel(:final stop):
        _focus(stop.lat, stop.lon, 16);
      case BusSel(:final line, :final vehicleId, :final at):
        final v = _vehicles(Deps.of(context).store).where((x) => x.id == vehicleId && x.line == line).firstOrNull;
        final p = v == null ? at : _glidePos(v, DateTime.now().millisecondsSinceEpoch ~/ 1000); // where it is drawn
        if (p != null) _focus(p.$1, p.$2, max(_map?.cameraPosition?.zoom ?? 15, 15));
      case LineSel(:final line):
        Deps.of(context).api.lineStatic(line).then((st) {
          if (identical(mapSel.value, s)) _fit(st); // not after another selection
        }).ignore();
      case null:
    }
  }

  // Puts a point in the middle of the map above the half-open sheet. The map moves to the point at
  // the target zoom, finds where it landed on screen (the camera's centre is not the view's middle on
  // Android), and glides so the point sits at the target height.
  Future<void> _focus(double lat, double lon, double zoom) async {
    final m = _map;
    if (m == null) return;
    final dpr = MediaQuery.devicePixelRatioOf(context);
    await m.moveCamera(CameraUpdate.newLatLngZoom(LatLng(lat, lon), zoom));
    final q = await m.toScreenLocation(LatLng(lat, lon));
    final want = _h * (1 - _half) / 2 * dpr; // device pixels from the top
    final c = await m.toLatLng(Point(q.x.toDouble(), 2 * q.y - want));
    await m.animateCamera(CameraUpdate.newLatLng(LatLng(c.latitude, lon)));
  }

  void _fit(LineStatic st) {
    var s = 90.0, w = 180.0, n = -90.0, e = -180.0;
    for (final v in st.variants.values) {
      for (final p in v.shape) {
        s = min(s, p.$1);
        n = max(n, p.$1);
        w = min(w, p.$2);
        e = max(e, p.$2);
      }
    }
    if (s > n || !mounted) return;
    _map?.animateCamera(CameraUpdate.newLatLngBounds(LatLngBounds(southwest: LatLng(s, w), northeast: LatLng(n, e)),
        left: 32, right: 32, top: 140, bottom: _h * _half + 24));
  }

  Future<void> _onStyle() async {
    final m = _map!;
    final api = Deps.of(context).api;
    _styled = false;
    _routesKey = '';
    _routesPending = null;
    _routesGen++;
    _rail = null;
    await m.addGeoJsonSource('metro', _empty);
    for (final tram in [false, true]) {
      final k = tram ? 'tram' : 'metro';
      await m.addLineLayer('metro', '$k-track',
          const LineLayerProperties(lineColor: ['get', 'color'], lineWidth: ['interpolate', ['linear'], ['zoom'], 10, 2, 14, 4, 17, 6], lineOpacity: .85, lineJoin: 'round', lineCap: 'round'),
          filter: ['all', ['==', ['geometry-type'], 'LineString'], ['==', ['get', 'tram'], tram]], enableInteraction: false);
    }
    await m.addGeoJsonSource('stops', _empty);
    await m.addCircleLayer('stops', 'stop-dot',
        const CircleLayerProperties(
          circleRadius: ['interpolate', ['linear'], ['zoom'], 14, 2.5, 16, 5, 18, 7],
          circleColor: '#FFFFFF',
          circleStrokeColor: '#5B5F66',
          circleStrokeWidth: ['interpolate', ['linear'], ['zoom'], 14, 1, 16, 2],
        ),
        minzoom: 14);
    // The open line's route: a white casing, the colour offset into its lane, and arrows.
    await m.addGeoJsonSource('routes', _empty);
    await m.addLineLayer('routes', 'route-casing',
        const LineLayerProperties(lineColor: '#FFFFFF', lineWidth: 8, lineOpacity: .9, lineOffset: _lanePx, lineJoin: 'round', lineCap: 'round'),
        enableInteraction: false);
    await m.addLineLayer('routes', 'route',
        const LineLayerProperties(lineColor: ['get', 'color'], lineWidth: 5, lineOffset: _lanePx, lineJoin: 'round', lineCap: 'round'));
    // Arrows as a glyph: an image added with addImage is not drawn on Android (maplibre-native #4326).
    await m.addSymbolLayer('routes', 'route-arrows',
        const SymbolLayerProperties(
          symbolPlacement: 'line',
          symbolSpacing: 70,
          textField: '›',
          textFont: ['Noto Sans Bold'],
          textSize: 20,
          textColor: '#FFFFFF',
          textHaloColor: '#33000000',
          textHaloWidth: 1,
          textRotationAlignment: 'map',
          textKeepUpright: false,
          textOffset: [0, .1], // into the lane (line-offset), a little under the glyph's centre
          textAllowOverlap: true,
          textIgnorePlacement: true,
        ),
        enableInteraction: false);
    await m.addGeoJsonSource('route-stops', _empty);
    await m.addCircleLayer('route-stops', 'route-stop',
        const CircleLayerProperties(circleRadius: ['interpolate', ['linear'], ['zoom'], 11, 3, 16, 6], circleColor: '#FFFFFF', circleStrokeColor: ['get', 'color'], circleStrokeWidth: 2.5),
        enableInteraction: false);
    await m.addGeoJsonSource('picked', _empty);
    await m.addCircleLayer('picked', 'picked-stop',
        const CircleLayerProperties(circleRadius: 9, circleColor: '#FFFFFF', circleStrokeColor: '#1A1C1E', circleStrokeWidth: 4),
        enableInteraction: false);
    for (final tram in [false, true]) {
      final k = tram ? 'tram' : 'metro';
      final pt = ['all', ['==', ['geometry-type'], 'Point'], ['==', ['get', 'tram'], tram]];
      await m.addCircleLayer('metro', '$k-station',
          const CircleLayerProperties(circleRadius: ['interpolate', ['linear'], ['zoom'], 10, 3, 15, 7], circleColor: '#FFFFFF', circleStrokeColor: ['get', 'color'], circleStrokeWidth: 3),
          filter: pt, enableInteraction: false);
      await m.addSymbolLayer('metro', '$k-name',
          const SymbolLayerProperties(textField: ['get', 'name'], textFont: ['Noto Sans Regular'], textSize: 11, textOffset: [0, 1.2], textColor: '#43474E', textHaloColor: '#FFFFFF', textHaloWidth: 1.5),
          filter: pt, minzoom: 13, enableInteraction: false);
    }
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
        minzoom: 13,
        enableInteraction: false);
    _styled = true;
    api.metro().then((j) => m.setGeoJsonSource('metro', metroGeo(j, name: titleCase))).catchError((_) {});
    _ix ??= await api.trips();
    if (mounted) setState(() {}); // the search can look up stops now
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

  // A line shown on the map in its own colour: one of mine keeps its slot, any other line is blue.
  String _hexOf(AppStore store, String line) => store.myLines.contains(line) ? hex(lineColor(store, line).bg) : hex(palette[0].bg);

  Future<void> _draw() async {
    final m = _map;
    if (m == null || !_styled || !mounted) return;
    final store = Deps.of(context).store;
    final sel = mapSel.value;
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final features = <Object>[];
    for (final v in _vehicles(store)) {
      final line = v.line ?? '';
      final on = switch (sel) { BusSel(line: final l, :final vehicleId) => l == line && vehicleId == v.id, LineSel(line: final l) => l == line, _ => false };
      final mine = store.myLines.contains(line);
      final c = mine ? lineColor(store, line) : (on ? palette[0] : const LineColor(Color(0xFF5B5F66), Colors.white));
      final p = _glidePos(v, now);
      features.add({
        'type': 'Feature',
        'id': 'v|$line|${v.id}',
        'properties': {'line': line, 'bg': hex(c.bg), 'fg': hex(c.fg)},
        'geometry': {'type': 'Point', 'coordinates': [p.$2, p.$1]},
      });
    }
    await m.setGeoJsonSource('vehicles', {'type': 'FeatureCollection', 'features': features});
    if (followBus.value && sel is BusSel) {
      final v = _vehicles(store).where((x) => x.id == sel.vehicleId && x.line == sel.line).firstOrNull;
      if (v != null) {
        final p = _glidePos(v, now);
        // Only after it moved: each focus ends in a camera-idle draw, which must not move the map again.
        if (_followedAt == null || distM(_followedAt!, p) > 40) {
          _followedAt = p;
          _focus(p.$1, p.$2, m.cameraPosition?.zoom ?? 16);
        }
      }
    } else {
      _followedAt = null;
    }
    await _drawRoutes(m, store, sel);
    final rail = (store.showMetro, store.showTram);
    if (rail != _rail) {
      _rail = rail;
      for (final id in ['metro-track', 'metro-station', 'metro-name']) {
        await m.setLayerVisibility(id, rail.$1);
      }
      for (final id in ['tram-track', 'tram-station', 'tram-name']) {
        await m.setLayerVisibility(id, rail.$2);
      }
    }
  }

  // The routes of what is open: one bus's direction, every direction of a line, or with "only my lines"
  // every visible line of mine; and the stop that is open.
  Future<void> _drawRoutes(MapLibreMapController m, AppStore store, MapSel? sel) async {
    final live = Deps.of(context).live;
    final api = Deps.of(context).api;
    final want = <String, Set<String>?>{}; // line → variants (null: all)
    switch (sel) {
      case BusSel(:final line, :final vehicleId, :final variant):
        final v = _vehicles(store).where((x) => x.id == vehicleId && x.line == line).firstOrNull ??
            (store.myLines.contains(line) ? live.lives[line]?.vehicles.where((x) => x.id == vehicleId).firstOrNull : null); // the hub keeps unwatched lines stale
        final vv = v?.variant ?? variant;
        want[line] = vv == null ? null : {vv};
      case LineSel(:final line):
        want[line] = null;
      case StopSel():
        break;
      case null:
        if (store.onlyMine) {
          for (final l in store.myLines.where((l) => !store.hiddenLines.contains(l))) {
            want[l] = null;
          }
        }
    }
    final picked = sel is StopSel ? sel.stop : null;
    final key = '${want.entries.map((e) => '${e.key}:${e.value}').join(',')}|${picked?.name}|${store.myLines}';
    if (key == _routesPending) return;
    if (key == _routesKey) {
      if (_routesPending != null) {
        _routesGen++; // back to what is drawn: the pending draw must not write
        _routesPending = null;
      }
      return;
    }
    _routesPending = key;
    final gen = ++_routesGen;
    bool stale() => !mounted || gen != _routesGen || !identical(_map, m);
    final statics = <String, LineStatic>{};
    for (final l in want.keys) {
      final st = live.statics[l] ?? await api.lineStatic(l).then<LineStatic?>((x) => x, onError: (_) => null);
      if (st != null) statics[l] = st;
    }
    if (stale()) return; // a newer draw (selection, filter, style) writes its own
    final drawn = [for (final e in want.entries) if (statics[e.key] case final st?) (line: e.key, color: _hexOf(store, e.key), st: st, only: e.value)];
    await m.setGeoJsonSource('routes', routesGeo(drawn));
    if (stale()) return;
    final one = sel is BusSel || sel is LineSel ? drawn.firstOrNull : null;
    await m.setGeoJsonSource('route-stops', one == null ? _empty : lineStopsGeo(one.st, one.color, variant: one.only?.firstOrNull));
    if (stale()) return;
    await m.setGeoJsonSource('picked', {
      'type': 'FeatureCollection',
      'features': [
        if (picked != null) {'type': 'Feature', 'properties': <String, Object>{}, 'geometry': {'type': 'Point', 'coordinates': [picked.lon, picked.lat]}},
      ],
    });
    if (stale()) return;
    _routesPending = null;
    if (statics.length == want.length) _routesKey = key; // a failed load is tried again on the next draw
  }

  void _tap(Point<double> point, LatLng at, String id, String layer, Annotation? annotation) {
    if (id.startsWith('v|')) {
      final p = id.split('|');
      final stop = switch (mapSel.value) { StopSel(:final stop) => stop, BusSel(:final stop) => stop, _ => null };
      mapSel.value = BusSel(p[1], p[2], stop: stop);
    } else if (id.startsWith('s') && _ix != null) {
      final i = int.tryParse(id.substring(1));
      if (i == null || i >= _ix!.s.length) return;
      final s = _ix!.s[i];
      mapSel.value = StopSel(StopRef(name: s.$1, lat: s.$2, lon: s.$3, lines: linesAt(_ix!, s.$1, s.$2, s.$3)));
    } else if (layer == 'route') {
      // route features have no id: the line comes from the open selection
      final line = switch (mapSel.value) { BusSel(:final line) => line, LineSel(:final line) => line, _ => null };
      if (line != null && mapSel.value is! LineSel) mapSel.value = LineSel(line);
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
    final sel = mapSel.value;
    return PopScope(
      canPop: sel == null,
      onPopInvokedWithResult: (popped, _) {
        if (!popped) mapSel.value = null;
      },
      child: ListenableBuilder(
        listenable: Listenable.merge([d.store, d.live]),
        builder: (context, _) {
          _draw();
          return LayoutBuilder(builder: (context, box) {
          final h = _h = box.maxHeight;
          return Stack(children: [
            MapLibreMap(
              styleString: style,
              initialCameraPosition: CameraPosition(target: LatLng(start.$1, start.$2), zoom: 14),
              myLocationEnabled: _me != null,
              trackCameraPosition: true,
              compassEnabled: false,
              // OSM credit: in the layers sheet; the button sits under the map's sheet
              attributionButtonPosition: AttributionButtonPosition.bottomLeft,
              attributionButtonMargins: const Point(4, 4),
              onMapCreated: (c) {
                _map = c;
                c.onFeatureTapped.add(_tap);
              },
              onMapClick: (_, _) {
                if (_sheet.isAttached && _sheet.size > _half + .05) _sheet.animateTo(_half, duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
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
                  if (d.live.isOffline) ...[const SizedBox(height: 10), _OfflineBanner(at: d.live.lastOkAt, now: d.live.nowS)],
                ]),
              ),
            ),
            // Map buttons ride on the sheet's edge and hide when it is nearly full.
            if (_extent < .7)
              Positioned(
                right: 16,
                bottom: h * _extent + 12,
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  FloatingActionButton.small(
                    heroTag: 'layers',
                    tooltip: 'Στρώματα χάρτη',
                    backgroundColor: t.ground,
                    foregroundColor: t.ink,
                    onPressed: () => _layers(context, d.store),
                    child: const Icon(Icons.layers_outlined),
                  ),
                  const SizedBox(height: 10),
                  FloatingActionButton(
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
                ]),
              ),
            NotificationListener<DraggableScrollableNotification>(
              onNotification: (n) {
                if ((n.extent - _extent).abs() > .01) setState(() => _extent = n.extent);
                return false;
              },
              child: DraggableScrollableSheet(
                controller: _sheet,
                initialChildSize: .3,
                minChildSize: _peek,
                maxChildSize: _full,
                snap: true,
                snapSizes: const [.3, _half],
                builder: (context, scroll) => Material(
                  color: t.ground,
                  elevation: 8,
                  shadowColor: const Color(0x33000000),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                  clipBehavior: Clip.antiAlias,
                  child: switch (sel) {
                    StopSel(:final stop) => StopPanel(key: ObjectKey(stop), stop: stop, scroll: scroll),
                    BusSel(:final line, :final vehicleId, :final stop) =>
                      VehiclePanel(key: ValueKey('$line|$vehicleId'), line: line, vehicleId: vehicleId, stop: stop, scroll: scroll),
                    LineSel(:final line) => LinePanel(key: ValueKey(line), line: line, scroll: scroll),
                    null => d.store.onlyMine ? _MyLinesSheet(scroll: scroll) : _NearSheet(me: _me, ix: _ix, scroll: scroll),
                  },
                ),
              ),
            ),
          ]);
          });
        },
      ),
    );
  }

  Future<void> _layers(BuildContext context, AppStore store) => showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        builder: (c) => ListenableBuilder(
          listenable: store,
          builder: (c, _) => SafeArea(
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Padding(padding: EdgeInsets.fromLTRB(24, 0, 24, 8), child: Text('Στον χάρτη', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600))),
              SwitchListTile(
                secondary: const Icon(Icons.subway_outlined),
                title: const Text('Μετρό και ΗΣΑΠ'),
                subtitle: const Text('γραμμές και σταθμοί'),
                value: store.showMetro,
                onChanged: (v) => store.setRail(metro: v),
              ),
              SwitchListTile(
                secondary: const Icon(Icons.tram_outlined),
                title: const Text('Τραμ'),
                subtitle: const Text('γραμμές και στάσεις'),
                value: store.showTram,
                onChanged: (v) => store.setRail(tram: v),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                child: Text('Χάρτης: © OpenStreetMap contributors · OpenFreeMap', style: TextStyle(fontSize: 12, color: c.tones.muted)),
              ),
            ]),
          ),
        ),
      );

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

// Screen 15: no network. The times below are estimates from the last data.
class _OfflineBanner extends StatelessWidget {
  const _OfflineBanner({required this.at, required this.now});
  final int? at;
  final int now;

  @override
  Widget build(BuildContext context) {
    final wall = at == null ? null : athensWall(DateTime.fromMillisecondsSinceEpoch(at! * 1000, isUtc: true));
    final when = wall == null ? '' : 'Τελευταία δεδομένα ${hm(wall.hour * 60 + wall.minute)} · πριν ${mins(now - at!)}';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(color: const Color(0xFF2F3033), borderRadius: BorderRadius.circular(16), boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 8, offset: Offset(0, 3))]),
      child: Row(children: [
        const Icon(Icons.wifi_off, color: Color(0xFFFFD27A)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Χωρίς σύνδεση', style: TextStyle(color: Color(0xFFF2F3F0), fontSize: 14, fontWeight: FontWeight.w600)),
            if (when.isNotEmpty) Text(when, style: const TextStyle(color: Color(0xFFC9CCD1), fontSize: 12)),
          ]),
        ),
      ]),
    );
  }
}

// The nearest saved stop (or the nearest stop) with the user's lines there.
class _NearSheet extends StatelessWidget {
  const _NearSheet({required this.me, required this.ix, required this.scroll});
  final Pt? me;
  final TripIndex? ix;
  final ScrollController scroll;

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
    return ListView(controller: scroll, padding: const EdgeInsets.fromLTRB(16, 0, 16, 12), children: [
      const SheetHandle(),
      Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
        Expanded(
          child: InkWell(
            onTap: name == null
                ? null
                : () async {
                    final ixx = ix ?? await d.api.trips();
                    final all = linesAt(ixx, name, lat!, lon!);
                    mapSel.value = StopSel(StopRef(name: name, lat: lat, lon: lon, lines: all.isEmpty ? lines : all));
                  },
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(dist == null ? (fav?.place == Place.work ? 'Δουλειά' : 'Η στάση σου') : 'Κοντά σου · ${dist.round()} μ.',
                  style: TextStyle(fontSize: 13, color: t.muted, fontWeight: FontWeight.w500)),
              Text(name == null ? 'Πάτα μια στάση στον χάρτη' : titleCase(name), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
            ]),
          ),
        ),
        const LiveNote(),
      ]),
      for (final (first, then) in groups)
        ArrivalRow(first: first, then: then, estimate: d.live.isOffline, onTap: () => mapSel.value = BusSel(first.line, first.vehicleId)),
      if (name != null && groups.isEmpty && lines.isNotEmpty)
        Padding(padding: const EdgeInsets.symmetric(vertical: 10), child: Text('Κανένα από ${lines.join(', ')} δεν έρχεται τώρα.', style: TextStyle(color: t.muted))),
    ]);
  }
}

// Screen 3's sheet: "Οι γραμμές μου τώρα" — buses on the road, how many are late, next at the stop.
class _MyLinesSheet extends StatelessWidget {
  const _MyLinesSheet({required this.scroll});
  final ScrollController scroll;

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
      rows.add(InkWell(
        onTap: () => mapSel.value = LineSel(l),
        child: Padding(
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
        ),
      ));
    }
    return ListView(controller: scroll, padding: const EdgeInsets.fromLTRB(16, 0, 16, 12), children: [
      const SheetHandle(),
      const Text('Οι γραμμές μου τώρα', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
      Text('τα άλλα λεωφορεία κρυμμένα · πάτα μια γραμμή για τη διαδρομή της', style: TextStyle(fontSize: 13, color: t.muted)),
      ...rows,
    ]);
  }
}
