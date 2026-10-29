// The home screen (docs/DESIGN-home.md): the map and one sheet, half open. Every vehicle from the
// snapshot tiles of the view (contract rev 5), or only the user's lines from /v1/lines; buses glide
// along their `path` between updates. A stop, a bus or a line opens in the sheet (one level at a time,
// «‹ Πίσω» and ✕), not on a new page; its route is drawn with arrows in travel direction, as on the
// web. With nothing open the sheet has two tabs: «Κοντά σου» (the smart card, then the nearest stops
// grouped by stop) and «Αγαπημένα». The layers and «πού είμαι» buttons show only with the sheet down.

import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/athens_time.dart';
import '../core/board.dart';
import '../core/eta.dart';
import '../core/geo.dart';
import '../core/home_sheet.dart';
import '../core/map_geo.dart';
import '../core/marker.dart';
import '../core/models.dart';
import '../core/motion.dart';
import '../core/near_home.dart';
import '../core/nearby.dart';
import '../core/rail.dart';
import '../data/basemap.dart';
import '../data/locate.dart';
import '../data/store.dart';
import 'go_home_card.dart';
import 'help.dart';
import 'favs_screen.dart';
import 'line_panel.dart';
import 'map_sel.dart';
import 'rules_screen.dart' show hm;
import 'search.dart';
import 'station_panel.dart';
import 'stop_screen.dart';
import 'theme.dart';
import 'vehicle_screen.dart';
import 'widgets.dart';

const _style = 'https://tiles.openfreemap.org/styles/';
const _box = (s: 37.5, w: 22.9, n: 38.5, e: 24.5); // tiles exist only here
const _lanePx = 3.0; // each direction drawn to the right of its travel direction (two lanes), as on the web
const _peek = .24, _half = .5, _full = .92; // _peek: the sheet down, its smart card still shows

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});
  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> with WidgetsBindingObserver {
  MapLibreMapController? _map;
  bool _styled = false;
  final _tiles = <String, List<Vehicle>>{}; // "z/x/y" → vehicles
  Set<String> _want = {};
  int _z = 13;
  Timer? _refresh, _glide;
  final _motion = Motion();
  // "Am I on a bus?": the phone's fixes and the shown buses near it, the last 90 s.
  Timer? _boardTimer;
  final _myTrack = <Fix>[];
  final _busTrack = <String, List<Fix>>{};
  String? _offered;
  Pt? _me;
  bool _located = false; // the first position request has answered (with a place or without)
  List<Station> _metroSt = const [], _railSt = const []; // for the nearest stops
  TripIndex? _ix;
  String? _styleFor;
  final _sheet = DraggableScrollableController();
  double _extent = _half;
  String _routesKey = ''; // what the route layers show now: redrawn only when it changes
  int _routesGen = 0; // the newest route draw; an older one stops before writing
  String? _routesPending; // the key being drawn: the same draw is not started twice
  Pt? _followedAt; // where "follow" last centred the bus
  (bool, bool, bool)? _rail; // metro, tram and suburban rail visibility applied to the map
  Map<String, dynamic>? _metroJson; // metro.json: a tapped station is found by its index
  double _h = 700; // the map's height: the sheet's sizes are fractions of it
  LineStatic? _routeSt; // the line whose stops are drawn on its route: a tap on one opens it
  String? _dark; // the lightened dark style (JSON); the plain URL until it loads
  final _near = NearMemo(); // the home sheet's nearest stops, searched again only when they can change

  @override
  void initState() {
    super.initState();
    _glide = Timer.periodic(const Duration(seconds: 1), (_) => _draw()); // the buses move between fixes
    _refresh = Timer.periodic(const Duration(seconds: 30), (_) => _loadTiles(force: true));
    _boardTimer = Timer.periodic(const Duration(seconds: 15), (_) => _sampleBoard());
    darkStyle().then((j) {
      if (mounted && j != null) setState(() => _dark = j);
    });
    mapSel.addListener(_onSel);
    WidgetsBinding.instance.addObserver(this);
    knownPosition().then((p) {
      if (!mounted) return;
      setState(() {
        _located = true;
        _me = p ?? _me;
      });
      if (p == null) return;
      if (mapSel.value == null) _map?.animateCamera(CameraUpdate.newLatLngZoom(LatLng(p.$1, p.$2), 15));
    });
  }

  @override
  void dispose() {
    mapSel.removeListener(_onSel);
    WidgetsBinding.instance.removeObserver(this);
    _refresh?.cancel();
    _glide?.cancel();
    _boardTimer?.cancel();
    _sheet.dispose();
    super.dispose();
  }

  // Paused: the boarding check starts its minute again.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) {
      _forgetTracks();
    } else {
      // Back in the app, maybe elsewhere or from the location settings: the nearest stops from a new
      // fix (never asks).
      quietPosition().then((p) {
        if (mounted && p != null) setState(() => _me = p);
      });
    }
  }

  void _forgetTracks() {
    _myTrack.clear();
    _busTrack.clear();
  }

  // A new selection: the sheet opens to half and the map moves to it.
  void _onSel() {
    if (!mounted) return;
    setState(() {});
    final s = mapSel.value;
    followBus.value = s is BusSel; // the map follows an open bus until the user moves the map
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_sheet.isAttached) _sheet.animateTo(_half, duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
    });
    _routesKey = '';
    _routesPending = null;
    _routesGen++;
    _draw();
    switch (s) {
      case StopSel(:final stop):
        _reveal(stop.lat, stop.lon);
      case BusSel(:final line, :final vehicleId, :final at):
        final v = _vehicles(Deps.of(context).store).where((x) => x.id == vehicleId && x.line == line).firstOrNull;
        final p = v == null ? at : _glidePos(v, DateTime.now().millisecondsSinceEpoch / 1000); // where it is drawn
        if (p != null) {
          _followedAt = p; // this focus is the first follow step
          _focus(p.$1, p.$2, max(_map?.cameraPosition?.zoom ?? 15, 15));
        }
      case PlaceSel(:final at):
        _focus(at.$1, at.$2, 16);
      case StationSel(:final at):
        _reveal(at.$1, at.$2);
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

  // A stop: the map keeps its zoom (from far out, 15) and moves only when the stop is off screen or
  // under the half-open sheet, so a tap on a stop does not jump the map.
  Future<void> _reveal(double lat, double lon) async {
    final m = _map;
    if (m == null) return;
    final z = m.cameraPosition?.zoom ?? 15;
    if (z < 14) return _focus(lat, lon, 15); // stops show from 14
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final w = MediaQuery.sizeOf(context).width;
    final q = await m.toScreenLocation(LatLng(lat, lon));
    final x = q.x / dpr, y = q.y / dpr;
    if (x > 24 && x < w - 24 && y > 120 && y < _h * (1 - _half) - 24) return;
    await _focus(lat, lon, z);
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
    final dark = Theme.of(context).brightness == Brightness.dark;
    final halo = dark ? '#1B1D21' : '#FFFFFF';
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
    // Suburban rail (Προαστιακός): its lines dashed, under the buses; stations tappable.
    await m.addGeoJsonSource('rail', _empty);
    await m.addLineLayer('rail', 'rail-track',
        const LineLayerProperties(lineColor: ['get', 'color'], lineWidth: ['interpolate', ['linear'], ['zoom'], 9, 1.5, 14, 3.5], lineDasharray: [2, 1.2], lineOpacity: .9),
        filter: ['==', ['geometry-type'], 'LineString'], enableInteraction: false);
    await m.addGeoJsonSource('stops', _empty);
    await m.addCircleLayer('stops', 'stop-dot',
        CircleLayerProperties(
          circleRadius: ['interpolate', ['linear'], ['zoom'], 14, 2.5, 16, 5, 18, 7],
          circleColor: dark ? '#2A2D33' : '#FFFFFF',
          circleStrokeColor: dark ? '#A8ADB5' : '#5B5F66',
          circleStrokeWidth: ['interpolate', ['linear'], ['zoom'], 14, 1, 16, 2],
        ),
        minzoom: 14,
        enableInteraction: false);
    // A stop is a few pixels wide: a clear circle around it takes the taps.
    await m.addCircleLayer('stops', 'stop-hit',
        const CircleLayerProperties(circleRadius: ['interpolate', ['linear'], ['zoom'], 14, 9, 16, 14], circleColor: '#000000', circleOpacity: 0),
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
    await m.addCircleLayer('route-stops', 'route-stop-hit',
        const CircleLayerProperties(circleRadius: ['interpolate', ['linear'], ['zoom'], 11, 8, 16, 14], circleColor: '#000000', circleOpacity: 0));
    await m.addGeoJsonSource('picked', _empty);
    await m.addCircleLayer('picked', 'picked-stop',
        const CircleLayerProperties(circleRadius: 7, circleColor: '#FFFFFF', circleStrokeColor: '#1A1C1E', circleStrokeWidth: 3),
        enableInteraction: false);
    await m.addCircleLayer('rail', 'rail-station',
        const CircleLayerProperties(circleRadius: ['interpolate', ['linear'], ['zoom'], 9, 2.5, 15, 7], circleColor: '#FFFFFF', circleStrokeColor: ['get', 'color'], circleStrokeWidth: 3),
        filter: ['==', ['geometry-type'], 'Point']);
    await m.addSymbolLayer('rail', 'rail-name',
        SymbolLayerProperties(textField: ['get', 'name'], textFont: ['Noto Sans Regular'], textSize: 11, textOffset: [0, 1.2], textColor: dark ? '#C9CCD1' : '#43474E', textHaloColor: halo, textHaloWidth: 1.5),
        filter: ['==', ['geometry-type'], 'Point'], minzoom: 12, enableInteraction: false);
    for (final tram in [false, true]) {
      final k = tram ? 'tram' : 'metro';
      final pt = ['all', ['==', ['geometry-type'], 'Point'], ['==', ['get', 'tram'], tram]];
      await m.addCircleLayer('metro', '$k-station',
          const CircleLayerProperties(circleRadius: ['interpolate', ['linear'], ['zoom'], 10, 3, 15, 7], circleColor: '#FFFFFF', circleStrokeColor: ['get', 'color'], circleStrokeWidth: 3),
          filter: pt);
      await m.addSymbolLayer('metro', '$k-name',
          SymbolLayerProperties(textField: ['get', 'name'], textFont: ['Noto Sans Regular'], textSize: 11, textOffset: [0, 1.2], textColor: dark ? '#C9CCD1' : '#43474E', textHaloColor: halo, textHaloWidth: 1.5),
          filter: pt, minzoom: 13, enableInteraction: false);
    }
    // Buses as on the web: filled by delay (my lines by their colour, with the delay as the ring), a
    // dark triangle ahead in travel direction, faded when the position is old, and its age beside.
    await m.addGeoJsonSource('vehicles', _empty);
    await m.addSymbolLayer('vehicles', 'veh-arrow',
        const SymbolLayerProperties(
          textField: '▲',
          textFont: ['Noto Sans Bold'],
          textSize: ['interpolate', ['linear'], ['zoom'], 13, 8, 16, 11],
          textRotate: ['get', 'hd'],
          textRotationAlignment: 'map',
          textOffset: [0, -1.25], // rotated with the glyph: always ahead of the dot
          textColor: '#222222',
          textHaloColor: '#FFFFFF',
          textHaloWidth: 1,
          textOpacity: ['get', 'op'],
          textAllowOverlap: true,
          textIgnorePlacement: true,
        ),
        filter: ['has', 'hd'],
        minzoom: 13,
        enableInteraction: false);
    await m.addCircleLayer('vehicles', 'veh-dot',
        const CircleLayerProperties(
          circleRadius: ['interpolate', ['linear'], ['zoom'], 10, 3, 13, 7, 16, 11],
          circleColor: ['get', 'bg'],
          circleStrokeColor: ['get', 'ring'],
          circleStrokeWidth: ['get', 'rw'],
          circleOpacity: ['get', 'op'],
          circleStrokeOpacity: ['get', 'op'],
        ));
    await m.addSymbolLayer('vehicles', 'veh-label',
        const SymbolLayerProperties(
          textField: ['get', 'line'],
          textFont: ['Noto Sans Bold'],
          textSize: ['interpolate', ['linear'], ['zoom'], 13, 8, 16, 11],
          textColor: ['get', 'fg'],
          textOpacity: ['get', 'op'],
          textAllowOverlap: true,
          textIgnorePlacement: true,
        ),
        minzoom: 13,
        enableInteraction: false);
    await m.addSymbolLayer('vehicles', 'veh-age',
        SymbolLayerProperties(
          textField: ['get', 'age'],
          textFont: ['Noto Sans Bold'],
          textSize: 10.5,
          textAnchor: 'left',
          textOffset: [1.3, 0],
          textColor: ['get', 'agec'],
          textHaloColor: halo,
          textHaloWidth: 1.5,
          textAllowOverlap: true,
          textIgnorePlacement: true,
        ),
        filter: ['has', 'age'],
        minzoom: 13,
        enableInteraction: false);
    _styled = true;
    api.metro().then((j) {
      _metroJson = j;
      if (mounted) setState(() => _metroSt = metroStations(j));
      return m.setGeoJsonSource('metro', metroGeo(j, name: titleCase));
    }).catchError((_) {});
    api.suburban().then((sub) {
      if (mounted) setState(() => _railSt = suburbanStations(sub));
      return m.setGeoJsonSource('rail', railGeo(sub, name: titleCase));
    }).catchError((_) {});
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
    if (mapSel.value != null && mounted) _onSel(); // opened before the map was ready (a tapped notification)
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

  // Where a vehicle is shown now: it drives along its path from the fix (typical speeds, stops), and a
  // new fix is joined smoothly instead of a jump (core/motion.dart, as on the web).
  Pt _glidePos(Vehicle v, double nowS) {
    final id = '${v.line}|${v.id}';
    _motion.update(id,
        path: v.path, speed: v.speed, positionAt: v.positionAt, pathSpeeds: v.pathSpeeds, fix: (v.lat, v.lon), nowS: nowS);
    return _motion.step(id, nowS);
  }

  // With the map open and location already allowed: a bus that moved with the phone for a minute
  // is offered once ("Είσαι στο 040;"), and its sheet has «Πού κατεβαίνω;».
  Future<void> _sampleBoard() async {
    bool shown() => mounted && mapShown(context);
    if (!shown()) {
      _myTrack.clear(); // a gap: the minute together starts again
      _busTrack.clear();
      return;
    }
    final p = await quietPosition();
    if (!mounted || !shown()) {
      _myTrack.clear();
      _busTrack.clear();
      return;
    }
    if (p == null) {
      _myTrack.clear();
      _busTrack.clear();
      return;
    }
    final t = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    // A gap (the app was paused, a page over the map): the minute together starts again.
    if (_myTrack.isNotEmpty && t - _myTrack.last.t > 25) {
      _myTrack.clear();
      _busTrack.clear();
    }
    _myTrack
      ..add((t: t, at: p))
      ..removeWhere((f) => t - f.t > 90);
    for (final v in _vehicles(Deps.of(context).store)) {
      final id = '${v.line}|${v.id}';
      final at = _motion.shown(id) ?? (v.lat, v.lon);
      if (distM(at, p) <= 400) (_busTrack[id] ??= []).add((t: t, at: at));
    }
    for (final l in _busTrack.values) {
      l.removeWhere((f) => t - f.t > 90);
    }
    _busTrack.removeWhere((_, l) => l.isEmpty);
    final id = boardedOn(_myTrack, _busTrack);
    if (id == null || id == _offered) return;
    _offered = id;
    final cut = id.indexOf('|');
    final line = id.substring(0, cut), vehicle = id.substring(cut + 1);
    if (mapSel.value case BusSel(line: final l, vehicleId: final v) when l == line && v == vehicle) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      duration: const Duration(seconds: 20),
      content: Text('Είσαι στο $line; Πες μου πού κατεβαίνεις.'),
      action: SnackBarAction(label: 'Άνοιξέ το', onPressed: () => showOnMap(BusSel(line, vehicle))),
    ));
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
        'path_speeds': v.pathSpeeds,
      });

  // A line shown on the map in its own colour: one of mine keeps its slot, any other line is blue.
  String _hexOf(AppStore store, String line) => store.myLines.contains(line) ? hex(lineColor(store, line).bg) : hex(palette[0].bg);

  Future<void> _draw() async {
    final m = _map;
    if (m == null || !_styled || !mounted) return;
    final store = Deps.of(context).store;
    final sel = mapSel.value;
    final nowS = DateTime.now().millisecondsSinceEpoch / 1000;
    final now = nowS ~/ 1;
    final features = <Object>[];
    final shown = <String>{};
    final focus = sel is BusSel || sel is LineSel;
    for (final v in _vehicles(store)) {
      final line = v.line ?? '';
      final on = switch (sel) {
        BusSel(line: final l, :final vehicleId) => l == line && vehicleId == v.id,
        LineSel(line: final l, :final variants) => l == line && (variants == null || variants.contains(v.variant)),
        _ => false,
      };
      // The open bus or line always shows; the filters and "the others" apply to the rest.
      if (!on && !keptBy(v, now, fresh: store.onlyFresh, onTime: store.onlyOnTime)) continue;
      if (focus && !on && store.others == Others.hide) continue;
      final mine = store.myLines.contains(line);
      final age = now - v.positionAt;
      final stale = age > staleS;
      final op = focus && !on && store.others == Others.dim ? .22 : (stale ? (mine ? .7 : .55) : 1.0); // old fixes fade, but late buses stay readable
      final delay = delayHex(v.delayS);
      final c = lineColor(store, line);
      final p = _glidePos(v, nowS);
      shown.add('$line|${v.id}');
      final hd = headingOf(v, p);
      features.add({
        'type': 'Feature',
        'id': 'v|$line|${v.id}',
        'properties': {
          'line': line,
          'bg': mine ? hex(c.bg) : delay,
          'fg': mine ? hex(c.fg) : '#FFFFFF',
          'ring': on ? '#1A73E8' : (mine ? delay : '#FFFFFF'),
          'rw': on ? 3.5 : (mine ? 3.0 : 1.5),
          'op': op,
          'hd': ?hd,
          if (store.showAges || stale) 'age': ago(age),
          'agec': stale ? '#D9480F' : '#5B5F66',
        },
        'geometry': {'type': 'Point', 'coordinates': [p.$2, p.$1]},
      });
    }
    _motion.retain(shown);
    await m.setGeoJsonSource('vehicles', {'type': 'FeatureCollection', 'features': features});
    if (followBus.value && sel is BusSel) {
      final v = _vehicles(store).where((x) => x.id == sel.vehicleId && x.line == sel.line).firstOrNull;
      if (v != null) {
        final p = _motion.shown('${v.line}|${v.id}') ?? _glidePos(v, nowS);
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
    final rail = (store.showMetro, store.showTram, store.showRail);
    if (rail != _rail) {
      _rail = rail;
      for (final id in ['rail-track', 'rail-station', 'rail-name']) {
        await m.setLayerVisibility(id, rail.$3);
      }
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
      case LineSel(:final line, :final variants):
        want[line] = variants;
      case StopSel() || PlaceSel() || StationSel():
        break;
      case null:
        if (store.onlyMine) {
          for (final l in store.myLines.where((l) => !store.hiddenLines.contains(l))) {
            want[l] = null;
          }
        }
    }
    final picked = switch (sel) {
      StopSel(:final stop) => (name: stop.name, lat: stop.lat, lon: stop.lon),
      PlaceSel(:final name, :final at) => (name: name, lat: at.$1, lon: at.$2),
      StationSel(:final name, :final at) => (name: name, lat: at.$1, lon: at.$2),
      _ => null,
    };
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
    _routeSt = one?.st;
    await m.setGeoJsonSource('route-stops', one == null ? _empty : lineStopsGeo(one.st, one.color, variants: one.only));
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
    if (id.startsWith('r|')) {
      Deps.of(context).api.suburban().then((sub) {
        final st = sub.stations[id.substring(2)];
        if (st != null) mapSel.value = StationSel(st.name, (st.lat, st.lon), lines: st.corridors, railId: st.id);
      });
    } else if (RegExp(r'^m\d+$').hasMatch(id) && _metroJson != null) {
      final list = _metroJson!['stations'] as List;
      final i = int.parse(id.substring(1));
      if (i >= list.length) return;
      final st = list[i] as Map<String, dynamic>;
      mapSel.value = StationSel(st['name'] as String, ((st['lat'] as num).toDouble(), (st['lon'] as num).toDouble()),
          lines: [for (final l in st['lines'] as List) l as String]);
    } else if (id.startsWith('v|')) {
      final p = id.split('|');
      final stop = switch (mapSel.value) { StopSel(:final stop) => stop, BusSel(:final stop) => stop, _ => null };
      mapSel.value = BusSel(p[1], p[2], stop: stop);
    } else if (id.startsWith('s') && _ix != null) {
      final i = int.tryParse(id.substring(1));
      if (i == null || i >= _ix!.s.length) return;
      final s = _ix!.s[i];
      mapSel.value = StopSel(StopRef(name: s.$1, lat: s.$2, lon: s.$3, lines: linesAt(_ix!, s.$1, s.$2, s.$3)));
    } else if (id.startsWith('rs|') && _routeSt?.stops[id.substring(3)] != null) {
      final s = _routeSt!.stops[id.substring(3)]!;
      mapSel.value = StopSel(StopRef(name: s.name, lat: s.lat, lon: s.lon, lines: _ix == null ? [_routeSt!.id] : linesAt(_ix!, s.name, s.lat, s.lon)));
    } else if (layer == 'route') {
      // A route opens its line, in the tapped direction (route features have no id: the line comes from
      // the open selection, the direction from the bus).
      final sel = mapSel.value;
      if (sel is BusSel) {
        final v = _vehicles(Deps.of(context).store).where((x) => x.id == sel.vehicleId && x.line == sel.line).firstOrNull;
        final vv = v?.variant ?? sel.variant;
        mapSel.value = LineSel(sel.line, variants: vv == null ? null : {vv});
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = Deps.of(context);
    final t = context.tones;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final style = dark ? _dark ?? '${_style}dark' : '${_style}positron';
    if (_styleFor != null && _styleFor != style) _styled = false;
    _styleFor = style;
    final start = _me ?? athensCentre;
    final sel = mapSel.value;
    // Back pops one sheet level; from the home sheet it leaves the app.
    return PopScope(
      canPop: sel == null,
      onPopInvokedWithResult: (popped, _) {
        if (popped) return;
        final menu = Scaffold.maybeOf(context);
        if (menu != null && menu.isDrawerOpen) return menu.closeDrawer(); // back closes the menu first
        mapBack();
      },
      child: ListenableBuilder(
        listenable: Listenable.merge([d.store, d.live]),
        builder: (context, _) {
          _draw();
          return LayoutBuilder(builder: (context, box) {
          final h = _h = box.maxHeight;
          return Stack(children: [
            // A drag or pinch on the map stops following the bus, as in every map app.
            Listener(
              onPointerMove: (_) => followBus.value = false,
              child: MapLibreMap(
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
              // An empty spot closes what is open, as on the web.
              onMapClick: (_, _) {
                if (mapSel.value != null) {
                  mapSel.value = null;
                } else if (_sheet.isAttached && _sheet.size > _half + .05) {
                  _sheet.animateTo(_half, duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
                }
              },
              onStyleLoadedCallback: _onStyle,
              onCameraIdle: _loadTiles,
            )),
            // Layers and «πού είμαι» only with the sheet down: they ride on its edge and fade in.
            Positioned(
              right: 16,
              bottom: h * _extent + 12,
              child: IgnorePointer(
                ignoring: _extent > _peek + .03,
                child: AnimatedOpacity(
                  opacity: _extent > _peek + .03 ? 0 : 1,
                  duration: MediaQuery.disableAnimationsOf(context) ? Duration.zero : const Duration(milliseconds: 150),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    _fab(t, 'layers', d.store.onlyMine ? 'Χάρτης: οι γραμμές μου' : 'Τι δείχνει ο χάρτης', Icons.layers_outlined,
                        on: d.store.onlyMine, () => _mapSheet(context, d.store)),
                    const SizedBox(height: 12),
                    _fab(t, 'locate', 'Πού είμαι', Icons.my_location, () async {
                      final p = await myPosition();
                      if (p == null) return;
                      setState(() => _me = p);
                      _map?.animateCamera(CameraUpdate.newLatLngZoom(LatLng(p.$1, p.$2), 15));
                    }),
                  ]),
                ),
              ),
            ),
            NotificationListener<DraggableScrollableNotification>(
              onNotification: (n) {
                if ((n.extent - _extent).abs() > .01) setState(() => _extent = n.extent);
                return false;
              },
              child: DraggableScrollableSheet(
                controller: _sheet,
                initialChildSize: _half,
                minChildSize: _peek,
                maxChildSize: _full,
                snap: true,
                snapSizes: const [_half],
                builder: (context, scroll) => Material(
                  color: t.ground,
                  elevation: 8,
                  shadowColor: const Color(0x33000000),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  clipBehavior: Clip.antiAlias,
                  child: switch (sel) {
                    StopSel(:final stop) => StopPanel(key: ObjectKey(stop), stop: stop, scroll: scroll),
                    BusSel(:final line, :final vehicleId, :final stop) =>
                      VehiclePanel(key: ValueKey('$line|$vehicleId'), line: line, vehicleId: vehicleId, stop: stop, scroll: scroll),
                    LineSel(:final line, :final variants) => LinePanel(key: ValueKey(line), line: line, variants: variants, scroll: scroll),
                    PlaceSel(:final name, :final at) => _PlacePanel(name: name, at: at, ix: _ix, scroll: scroll),
                    StationSel() => StationPanel(key: ObjectKey(sel), sel: sel, ix: _ix, scroll: scroll),
                    null => _HomeSheet(
                        me: _me,
                        memo: _near,
                        located: _located,
                        ix: _ix,
                        stations: [..._metroSt, ..._railSt],
                        scroll: scroll,
                        onLocate: () async {
                          final p = await askPosition();
                          if (!mounted || p == null) return;
                          setState(() => _me = p);
                          _map?.animateCamera(CameraUpdate.newLatLngZoom(LatLng(p.$1, p.$2), 15));
                        },
                      ),
                  },
                ),
              ),
            ),
            // Last, so the search results lie over the map buttons and the sheet.
            if (_extent < .8)
              SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Flexible(
                    child: SearchField(
                      ix: _ix,
                      leading: IconButton(tooltip: 'Μενού', icon: const Icon(Icons.menu), onPressed: () => Scaffold.of(context).openDrawer()),
                    ),
                  ),
                  if (d.live.isOffline) ...[const SizedBox(height: 4), _OfflineBanner(at: d.live.lastOkAt, now: d.live.nowS)],
                ]),
              ),
            ),
          ]);
          });
        },
      ),
    );
  }

  // One «Χάρτης» sheet for everything the map shows: what buses (all, or my lines and which), metro,
  // tram and rail, the colours' strip; the rarer view settings fold under «Για προχωρημένους».
  Future<void> _mapSheet(BuildContext context, AppStore store) => showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        isScrollControlled: true,
        builder: (c) => ListenableBuilder(
          listenable: store,
          builder: (c, _) {
            void only(bool v) {
              store.setOnlyMine(v);
              if (!v) _loadTiles(force: true);
            }

            return SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    const Expanded(child: Text('Χάρτης', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600))),
                    IconButton(tooltip: 'Τι σημαίνει κάθε σύμβολο', icon: const Icon(Icons.help_outline), onPressed: () => showMapHelp(c)),
                  ]),
                  const SizedBox(height: 4),
                  if (store.myLines.isEmpty)
                    Text('Λεωφορεία: όλα. Βάλε αστέρι σε μια γραμμή για να βλέπεις μόνο τις δικές σου.', style: TextStyle(fontSize: 13, color: c.tones.muted))
                  else ...[
                    SizedBox(
                      width: double.infinity,
                      child: SegmentedButton<bool>(
                        segments: const [
                          ButtonSegment(value: false, label: Text('Όλα τα λεωφορεία')),
                          ButtonSegment(value: true, label: Text('Οι γραμμές μου')),
                        ],
                        selected: {store.onlyMine},
                        onSelectionChanged: (v) => only(v.first),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(spacing: 6, runSpacing: 6, children: [
                      for (final l in store.myLines)
                        FilterChip(
                          label: Text(l, style: const TextStyle(fontWeight: FontWeight.w700)),
                          selected: store.onlyMine && !store.hiddenLines.contains(l),
                          onSelected: (show) {
                            if (!store.onlyMine) only(true); // picking a line means: show only my lines
                            if (store.hiddenLines.contains(l) == show) store.toggleHidden(l);
                          },
                        ),
                    ]),
                  ],
                  const SizedBox(height: 12),
                  Wrap(spacing: 8, runSpacing: 8, children: [
                    FilterChip(avatar: const Icon(Icons.subway_outlined, size: 18), label: const Text('Μετρό'), selected: store.showMetro, onSelected: (v) => store.setRail(metro: v)),
                    FilterChip(avatar: const Icon(Icons.tram_outlined, size: 18), label: const Text('Τραμ'), selected: store.showTram, onSelected: (v) => store.setRail(tram: v)),
                    FilterChip(avatar: const Icon(Icons.train_outlined, size: 18), label: const Text('Προαστιακός'), selected: store.showRail, onSelected: (v) => store.setRail(rail: v)),
                  ]),
                  const SizedBox(height: 12),
                  const DelayLegend(),
                  Theme(
                    data: Theme.of(c).copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      tilePadding: EdgeInsets.zero,
                      title: const Text('Για προχωρημένους', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                      children: [
                        const Align(alignment: Alignment.centerLeft, child: Text('Όταν πατάς ένα λεωφορείο ή μια γραμμή, τα άλλα:')),
                        const SizedBox(height: 6),
                        SizedBox(
                          width: double.infinity,
                          child: SegmentedButton<Others>(
                            segments: const [
                              ButtonSegment(value: Others.normal, label: Text('Φαίνονται')),
                              ButtonSegment(value: Others.dim, label: Text('Αχνά')),
                              ButtonSegment(value: Others.hide, label: Text('Κρύβονται')),
                            ],
                            selected: {store.others},
                            onSelectionChanged: (v) => store.setMapView(others: v.first),
                          ),
                        ),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Μόνο με πρόσφατη θέση'),
                          subtitle: const Text('Έστειλαν θέση τα τελευταία 1½ λεπτά.'),
                          value: store.onlyFresh,
                          onChanged: (v) => store.setMapView(fresh: v),
                        ),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Μόνο στην ώρα τους'),
                          subtitle: const Text('Έως 5 λεπτά καθυστέρηση.'),
                          value: store.onlyOnTime,
                          onChanged: (v) => store.setMapView(onTime: v),
                        ),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Πόσο παλιά είναι η θέση'),
                          subtitle: const Text('Δίπλα σε κάθε λεωφορείο. Οι παλιές φαίνονται πάντα.'),
                          value: store.showAges,
                          onChanged: (v) => store.setMapView(ages: v),
                        ),
                      ],
                    ),
                  ),
                  Text('Χάρτης: © OpenStreetMap contributors · OpenFreeMap', style: TextStyle(fontSize: 12, color: c.tones.muted)),
                ]),
              ),
            );
          },
        ),
      );

  // A round map button over the map; [on]: the map shows only my lines.
  Widget _fab(Tones t, String tag, String tip, IconData icon, VoidCallback onTap, {bool on = false}) => FloatingActionButton(
        heroTag: tag,
        tooltip: tip,
        mini: true,
        shape: const CircleBorder(),
        backgroundColor: on ? t.indicator : t.ground,
        foregroundColor: tag == 'locate' ? const Color(0xFF1A73E8) : t.ink,
        onPressed: onTap,
        child: Icon(icon),
      );
}

/// The map is the page on top (no menu page over it) and the app is in front.
bool mapShown(BuildContext context) =>
    (ModalRoute.of(context)?.isCurrent ?? true) && WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;

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

// Nothing open: two tabs, «Κοντά σου» and «Αγαπημένα», then the smart card. «Κοντά σου»: the nearest
// bus stop with my lines, the nearest rail station, then the rest, each grouped by stop (or, with "only
// my lines", where those lines are now). Without the user's position (no permission, location off,
// still looking) a way to allow it.
class _HomeSheet extends StatelessWidget {
  const _HomeSheet({required this.me, required this.memo, required this.located, required this.ix, required this.stations, required this.scroll, required this.onLocate});
  final Pt? me;
  final NearMemo memo;
  final bool located;
  final TripIndex? ix;
  final List<Station> stations;
  final ScrollController scroll;
  final VoidCallback onLocate;

  @override
  Widget build(BuildContext context) => ValueListenableBuilder(
        valueListenable: homeTab,
        builder: (context, tab, _) => ListView(controller: scroll, padding: const EdgeInsets.fromLTRB(16, 0, 16, 16), children: [
          const SheetHandle(),
          _Tabs(tab: tab),
          const SizedBox(height: 8),
          SmartCard(me: me, ix: ix),
          ...tab == 0 ? _near(context) : _favs(context),
        ]),
      );

  List<Widget> _near(BuildContext context) {
    final d = Deps.of(context);
    final t = context.tones;
    if (d.store.onlyMine) return [const _MyLines()];
    final here = me;
    if (here == null) {
      return [
        if (!located)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(children: [
              const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
              const SizedBox(width: 10),
              Text('Βρίσκω τη θέση σου…', style: TextStyle(color: t.muted)),
            ]),
          )
        else
          // The reason first; the phone's question comes only after the button.
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: t.surface, borderRadius: BorderRadius.circular(14)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Δες τι περνάει κοντά σου', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text('Με την τοποθεσία σου δείχνω τις πιο κοντινές στάσεις και πότε έρχεται το λεωφορείο. Η θέση μένει στο κινητό.',
                  style: TextStyle(fontSize: 13.5, height: 1.35, color: t.muted)),
              const SizedBox(height: 10),
              FilledButton.icon(onPressed: onLocate, icon: const Icon(Icons.my_location), label: const Text('Χρήση της θέσης μου')),
              const SizedBox(height: 4),
              Text('Ή γράψε μια στάση ή γραμμή στην αναζήτηση.', style: TextStyle(fontSize: 12.5, color: t.muted)),
            ]),
          ),
      ];
    }
    final shown = [
      for (final s in stations)
        if (s.railId != null ? d.store.showRail : s.lines.every((l) => l.startsWith('T')) ? d.store.showTram : d.store.showMetro) s,
    ];
    final groups = homeGroups(memo.places(ix, shown, here), d.store.myLines);
    if (groups.isEmpty) {
      return [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(ix == null ? 'Φορτώνω τις στάσεις…' : 'Καμία στάση σε 2,5 χλμ.', style: TextStyle(color: t.muted)),
        ),
      ];
    }
    return [
      for (final (i, p) in groups.indexed) ...[
        if (i > 0) Divider(height: 1, color: t.rule),
        _StopGroup(place: p, ix: ix, mine: myLinesHere(p, d.store.myLines), others: true),
        if (i == 1 && groups.length > 2)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Center(child: Text('σύρε για περισσότερες στάσεις', style: TextStyle(fontSize: 12.5, color: t.muted))),
          ),
      ],
      const Padding(padding: EdgeInsets.only(top: 8), child: LiveNote()),
    ];
  }

  // The saved stops, each with its lines' next bus, and the saved lines; the full page manages them.
  List<Widget> _favs(BuildContext context) {
    final d = Deps.of(context);
    final t = context.tones;
    final favs = d.store.favsByTime(DateTime.now().toUtc());
    return [
      if (favs.isEmpty)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text('Καμία αποθηκευμένη στάση ακόμη. Άνοιξε μια στάση και πάτα το αστέρι.', style: TextStyle(color: t.muted)),
        ),
      for (final (i, f) in favs.indexed) ...[
        if (i > 0) Divider(height: 1, color: t.rule),
        _StopGroup(
          place: NearPlace(kind: NearKind.bus, name: f.name, lat: f.lat, lon: f.lon, distM: me == null ? -1 : distM(me!, (f.lat, f.lon)), lines: f.lines),
          ix: ix,
          mine: f.lines,
          others: false,
        ),
      ],
      if (d.store.myLines.isNotEmpty) ...[
        Padding(
          padding: const EdgeInsets.only(top: 12, bottom: 8),
          child: Text('Οι γραμμές μου', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: t.muted)),
        ),
        Wrap(spacing: 6, runSpacing: 6, children: [for (final l in d.store.myLines) LineButton(l)]),
      ],
      const SizedBox(height: 8),
      Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(
          onPressed: () => openPage('Αγαπημένα', const FavsScreen()),
          icon: const Icon(Icons.edit_outlined, size: 18),
          label: const Text('Όλα τα αγαπημένα · προσθήκη, σπίτι, δουλειά'),
        ),
      ),
    ];
  }
}

// «Κοντά σου» / «Αγαπημένα» as two text tabs; the open one dark and underlined.
class _Tabs extends StatelessWidget {
  const _Tabs({required this.tab});
  final int tab;

  @override
  Widget build(BuildContext context) {
    final t = context.tones;
    Widget one(int i, String label, {IconData? icon}) {
      final on = tab == i;
      final c = on ? t.ink : t.muted;
      return Semantics(
        selected: on,
        button: true,
        child: InkWell(
          onTap: () => homeTab.value = i,
          child: Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            margin: const EdgeInsets.only(right: 20),
            decoration: BoxDecoration(border: Border(bottom: BorderSide(color: on ? t.ink : Colors.transparent, width: 2))),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              if (icon != null) ...[Icon(icon, size: 18, color: c), const SizedBox(width: 4)],
              Text(label, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: c)),
            ]),
          ),
        ),
      );
    }

    return Row(children: [one(0, 'Κοντά σου'), one(1, 'Αγαπημένα', icon: Icons.star_outline)]);
  }
}

// One stop or station: its name and kind (and how far), the walk button, then its lines as pills
// (badge + minutes) that wrap. A bus stop: [mine] with their next bus, then, if [others], the other
// lines there; a station, the next departure of each line and direction. A tap opens it, as a tap on
// the map does.
class _StopGroup extends StatelessWidget {
  const _StopGroup({required this.place, required this.ix, required this.mine, required this.others});
  final NearPlace place;
  final TripIndex? ix;
  final List<String> mine;
  final bool others;

  void _open() {
    final p = place;
    if (p.kind == NearKind.bus) {
      final all = ix == null ? const <String>[] : linesAt(ix!, p.name, p.lat, p.lon);
      mapSel.value = StopSel(StopRef(name: p.name, lat: p.lat, lon: p.lon, lines: all.isEmpty ? p.lines : all));
    } else {
      mapSel.value = StationSel(p.name, (p.lat, p.lon), lines: p.lines, railId: p.railId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = Deps.of(context);
    final t = context.tones;
    final p = place;
    final groups = mine.isEmpty ? const <(Arrival, List<Arrival>)>[] : groupArrivals(d.live.arrivalsNear(p.name, p.lat, p.lon, only: mine));
    final next = [for (final (a, _) in groups) a]; // soonest first, one per line and direction
    final twice = {for (final a in next) if (next.where((b) => b.line == a.line).length > 1) a.line};
    final quiet = [for (final l in mine) if (!next.any((a) => a.line == l)) l];
    final rest = others ? [for (final l in p.lines) if (!mine.contains(l)) l].take(8).toList() : const <String>[];
    return InkWell(
      onTap: _open,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(titleCase(p.name), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                Text([kindLabel(p.kind), if (p.distM >= 0) distLabel(p.distM)].join(' · '), style: TextStyle(fontSize: 12, color: t.muted)),
              ]),
            ),
            const SizedBox(width: 8),
            _WalkButton(place: p),
          ]),
          if (p.kind != NearKind.bus)
            _StationNext(key: ValueKey('${p.kind.name}|${p.name}'), place: p)
          else if (next.isNotEmpty || rest.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Wrap(spacing: 6, runSpacing: 6, children: [
                for (final a in next)
                  _Pill(
                    badge: _PillBadge(line: a.line),
                    towards: twice.contains(a.line) ? titleCase(a.headsign) : null, // two directions here: say which
                    when: '${d.live.isOffline ? '~' : ''}${mins(a.etaS)}',
                  ),
                for (final l in rest) _Pill(badge: _PillBadge(line: l)),
              ]),
            ),
          if (quiet.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text('${quiet.join(', ')}: κανένα λεωφορείο με GPS τώρα', style: TextStyle(fontSize: 12.5, color: t.muted)),
            ),
        ]),
      ),
    );
  }
}

// Walking person and minutes: Google Maps walking directions to the stop (the web page without the app).
class _WalkButton extends StatelessWidget {
  const _WalkButton({required this.place});
  final NearPlace place;

  Future<void> _go() async {
    final p = place;
    try {
      if (await launchUrl(walkUri(p.lat, p.lon), mode: LaunchMode.externalApplication)) return;
    } catch (_) {/* no Google Maps app */}
    await launchUrl(walkWebUri(p.lat, p.lon), mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tones;
    final m = place.distM >= 0 ? walkMin(place.distM) : null;
    return Semantics(
      label: m == null ? 'Οδηγίες με τα πόδια' : 'Οδηγίες με τα πόδια, $m λεπτά',
      button: true,
      excludeSemantics: true,
      child: SizedBox(
        height: 48, // the touch target; the outline is 36
        child: Center(
          child: Material(
            color: t.ground,
            shape: StadiumBorder(side: BorderSide(color: t.outline, width: 1.5)),
            child: InkWell(
              customBorder: const StadiumBorder(),
              onTap: _go,
              child: Container(
                height: 36,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.directions_walk, size: 20, color: t.accent),
                  if (m != null) Text('$m′', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: t.accent)),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// A line's pill: its badge, then (when known) where it goes and the minutes, largest.
class _Pill extends StatelessWidget {
  const _Pill({required this.badge, this.towards, this.when, this.note});
  final Widget badge;
  final String? towards, when, note;

  @override
  Widget build(BuildContext context) {
    final t = context.tones;
    return Container(
      height: 32,
      padding: EdgeInsets.fromLTRB(4, 0, when == null ? 4 : 10, 0),
      decoration: BoxDecoration(color: t.surface, borderRadius: BorderRadius.circular(16)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        badge,
        if (towards != null)
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 130),
            child: Text(' → $towards', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12.5, color: t.muted)),
          ),
        if (note != null) Text(' $note', style: TextStyle(fontSize: 12, color: t.late, fontWeight: FontWeight.w600)),
        if (when != null) Text('  $when', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
      ]),
    );
  }
}

// A small line badge for a pill: the line's colour from the store, or a given one (metro, tram).
class _PillBadge extends StatelessWidget {
  const _PillBadge({required this.line, this.bg, this.fg});
  final String line;
  final Color? bg, fg;

  @override
  Widget build(BuildContext context) {
    final c = lineColor(Deps.of(context).store, line);
    return Container(
      constraints: const BoxConstraints(minWidth: 34),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(color: bg ?? c.bg, borderRadius: BorderRadius.circular(12)),
      child: Text(line, textAlign: TextAlign.center, style: TextStyle(color: fg ?? c.fg, fontSize: 13, fontWeight: FontWeight.w700)),
    );
  }
}

// A near station's next departures, every line (a station has few): metro and tram from the STASY
// timetable on our backend, suburban trains live from railway.gov.gr. Nothing while it loads or when
// there is no data: the row keeps its lines.
class _StationNext extends StatefulWidget {
  const _StationNext({super.key, required this.place});
  final NearPlace place;

  @override
  State<_StationNext> createState() => _StationNextState();
}

class _StationNextState extends State<_StationNext> {
  List<List<Map<String, dynamic>>> _answers = const [];
  int _at = 0; // Unix s of the metro answers
  List<RailDeparture> _trains = const [];
  Suburban? _sub;
  Timer? _timer;
  int _ticks = 0;

  // Its own clock: the minutes count down every 10 s (the live buses may tick nothing), a new list
  // every minute, none while the map is hidden or the app is in the background.
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_timer == null) {
      _load();
      _timer = Timer.periodic(const Duration(seconds: 10), (_) {
        if (!mapShown(context)) return;
        if (++_ticks % 6 == 0) _load();
        if (mounted) setState(() {});
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    final api = Deps.of(context).api;
    final p = widget.place;
    try {
      if (p.railId != null) {
        _sub ??= await api.suburban();
        final trains = await api.railDepartures(p.railId!);
        if (mounted) setState(() => _trains = trains);
      } else {
        final names = p.names.isEmpty ? [p.name] : p.names;
        int nowS() => DateTime.now().millisecondsSinceEpoch ~/ 1000;
        // Each answer with the time it came, so a slow one does not age the others; a failed one is null.
        final got = await Future.wait(names.map((n) => api.stasyDepartures(n).then<(int, Map<String, dynamic>?)?>((j) => (nowS(), j)).catchError((Object _) => null)));
        if (got.every((g) => g?.$2 == null)) return; // offline or not served now (503): the last list stays
        final at = nowS();
        final answers = [
          for (final g in got)
            if (g case (final t, final j?))
              [
                for (final d in j['departures'] as List? ?? const [])
                  {...d as Map<String, dynamic>, 'in_s': ((d['in_s'] as num?) ?? 0).toInt() - (at - t)},
              ],
        ];
        if (mounted) {
          setState(() {
            _answers = answers;
            _at = at;
          });
        }
      }
    } catch (_) {/* offline: the last list stays */}
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tones;
    final now = DateTime.now().toUtc();
    final pills = <Widget>[];
    if (widget.place.railId != null) {
      for (final d in nextTrains(_trains, now)) {
        final ends = _sub?.towards(widget.place.railId!, d.next) ?? const <String>{};
        final late = (d.delayMin ?? 0) > 0 && !d.cancelled;
        pills.add(_Pill(
          badge: const Padding(padding: EdgeInsets.symmetric(horizontal: 4), child: Icon(Icons.train_outlined, size: 18)),
          towards: ends.isNotEmpty ? ends.map(titleCase).join(' / ') : titleCase(d.next),
          when: d.cancelled ? 'ακυρώθηκε' : mins(d.expected.difference(now).inSeconds),
          note: late ? '+${d.delayMin}′' : null,
        ));
      }
    } else {
      final elapsed = now.millisecondsSinceEpoch ~/ 1000 - _at;
      for (final d in nextByDirection(_answers, elapsedS: elapsed, here: widget.place.names.isEmpty ? [widget.place.name] : widget.place.names)) {
        final c = int.tryParse((d.color ?? '').replaceFirst('#', ''), radix: 16);
        pills.add(_Pill(
          badge: _PillBadge(line: d.line, bg: c == null ? t.ink : Color(0xFF000000 | c), fg: Colors.white),
          towards: titleCase(d.towards),
          when: mins(d.inS),
        ));
      }
    }
    // No departures (loading, offline, not served now): the station's lines, as before.
    if (pills.isEmpty) {
      final p = widget.place;
      return Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(p.railId != null ? 'Προαστιακός · ${p.lines.join(', ')}' : p.lines.join(', '), style: TextStyle(fontSize: 13, color: t.muted)),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Wrap(spacing: 6, runSpacing: 6, children: pills),
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(widget.place.railId != null ? 'live από railway.gov.gr' : 'πρόγραμμα ΣΤΑΣΥ, όχι live', style: TextStyle(fontSize: 11.5, color: t.muted)),
        ),
      ]),
    );
  }
}

// A place or an address from the search: the stops around it, nearest first.
class _PlacePanel extends StatelessWidget {
  const _PlacePanel({required this.name, required this.at, required this.ix, required this.scroll});
  final String name;
  final Pt at;
  final TripIndex? ix;
  final ScrollController scroll;

  @override
  Widget build(BuildContext context) {
    final t = context.tones;
    final stops = ix == null ? const <NearbyStop>[] : nearbyStops(ix!, at, radiusM: 600, max: 6);
    return ListView(controller: scroll, padding: const EdgeInsets.fromLTRB(16, 0, 16, 24), children: [
      const SheetHandle(),
      Row(children: [
        const BackSel(),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Στάσεις κοντά', style: TextStyle(fontSize: 13, color: t.muted, fontWeight: FontWeight.w500)),
            Text(name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
          ]),
        ),
        const CloseSel(),
      ]),
      const SizedBox(height: 4),
      if (stops.isEmpty) Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Text('Καμία στάση σε 600 μ.', style: TextStyle(color: t.muted))),
      for (final s in stops)
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.directions_bus_outlined),
          title: Text(titleCase(s.name)),
          subtitle: Text('${s.distM.round()} μ. · ${s.lines.take(8).join(', ')}', maxLines: 1, overflow: TextOverflow.ellipsis),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => mapSel.value = StopSel(StopRef(name: s.name, lat: s.lat, lon: s.lon, lines: linesAt(ix!, s.name, s.lat, s.lon))),
        ),
    ]);
  }
}

// «Κοντά σου» with "only my lines": "Οι γραμμές μου τώρα" — buses on the road, how many are late,
// next at the stop.
class _MyLines extends StatelessWidget {
  const _MyLines();

  // Its own listener: a const widget is not rebuilt with the sheet when the buses move.
  @override
  Widget build(BuildContext context) => ListenableBuilder(listenable: Deps.of(context).live, builder: (context, _) => _rows(context));

  Widget _rows(BuildContext context) {
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
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Οι γραμμές μου τώρα', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
      Text('τα άλλα λεωφορεία κρυμμένα · πάτα μια γραμμή για τη διαδρομή της', style: TextStyle(fontSize: 13, color: t.muted)),
      ...rows,
      if (rows.isEmpty)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Text('Καμία γραμμή επιλεγμένη. Διάλεξε από το κουμπί του χάρτη (κατέβασε το φύλλο).', style: TextStyle(color: t.muted)),
        ),
    ]);
  }
}
