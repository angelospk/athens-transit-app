// HTTP access to the athens-transit backend (contract: athens-transit-map/docs/CONTRACT.md).
// Live data comes from transit.haroldpoi.dev, static data from the backend's GitHub Pages, and the
// trip index (every stop with the lines that stop there) from the web app's trips.json.

import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/models.dart';
import 'cache.dart';

const apiBase = 'https://transit.haroldpoi.dev';
const staticBase = 'https://angelospk.github.io/athens-transit-rt/static/v1';
const tripsUrl = 'https://bus.haroldpoi.dev/trips.json';
const metroUrl = 'https://bus.haroldpoi.dev/metro.json'; // metro, ISAP, tram: STASY GTFS + OSM tracks
const pushBase = 'https://push.haroldpoi.dev';

class ApiError implements Exception {
  ApiError(this.status, this.url);
  final int status;
  final String url;
  bool get rateLimited => status == 429;
  bool get warmingUp => status == 503;
  @override
  String toString() => 'HTTP $status $url';
}

class Api {
  Api({http.Client? client, DiskCache? cache})
      : _client = client ?? http.Client(),
        _cache = cache ?? DiskCache();

  final http.Client _client;
  final DiskCache _cache;

  Future<dynamic> _get(String url) async {
    final r = await _client.get(Uri.parse(url)).timeout(const Duration(seconds: 15));
    if (r.statusCode != 200) throw ApiError(r.statusCode, url);
    return jsonDecode(utf8.decode(r.bodyBytes));
  }

  // Static files change only with a new GTFS: serve the disk copy at once and refresh it behind.
  Future<dynamic> _static(String key, String url) async {
    final saved = await _cache.read(key);
    if (saved != null) {
      _get(url).then((j) => _cache.write(key, j)).ignore();
      return saved;
    }
    final j = await _get(url);
    await _cache.write(key, j);
    return j;
  }

  // One request per key at a time; a failed one is forgotten so the next call tries again.
  final _memo = <String, Future<Object?>>{};
  Future<T> _once<T>(String key, Future<T> Function() make) {
    final f = (_memo[key] ??= make()) as Future<T>;
    f.then((_) {}, onError: (_) {
      if (identical(_memo[key], f)) _memo.remove(key);
    });
    return f;
  }

  Future<List<LineInfo>> lines() => _once('lines', () => _static('lines', '$staticBase/lines.json').then(parseLines));

  Future<TripIndex> trips() => _once('trips', () => _static('trips', tripsUrl).then((j) => TripIndex.fromJson(j)));

  Future<LineStatic> lineStatic(String line) => _once('line_$line',
      () => _static('line_$line', '$staticBase/lines/${Uri.encodeComponent(line)}.json').then((j) => LineStatic.fromJson(j)));

  // GeoJSON-ready raw data: {lines: [{id, name, color, paths: [[[lon, lat]...]...]}], stations: [...]}.
  Future<Map<String, dynamic>> metro() => _once('metro', () async => (await _static('metro', metroUrl)) as Map<String, dynamic>);

  Future<LineLive> live(String line) async {
    final j = await _get('$apiBase/v1/lines/${Uri.encodeComponent(line)}');
    await _cache.write('live_$line', j).catchError((_) {}); // a failed save must not fail the fetch
    return LineLive.fromJson(j);
  }

  // The last live copy of a line, for the offline estimate.
  Future<LineLive?> savedLive(String line) async {
    final j = await _cache.read('live_$line');
    return j == null ? null : LineLive.fromJson(j);
  }

  Future<VehicleTile> tile(int z, int x, int y) async {
    final j = await _get('$apiBase/v1/vehicles/tiles/$z/$x/$y');
    return VehicleTile(
      updatedAt: j['updated_at'] as int,
      nextUpdateAt: j['next_update_at'] as int,
      vehicles: [for (final v in j['vehicles'] as List) Vehicle.fromJson(v as Map<String, dynamic>)],
    );
  }

  Future<Map<String, dynamic>> status() async => (await _get('$apiBase/v1/status')) as Map<String, dynamic>;
}

class VehicleTile {
  VehicleTile({required this.updatedAt, required this.nextUpdateAt, required this.vehicles});
  final int updatedAt, nextUpdateAt;
  final List<Vehicle> vehicles;
}
