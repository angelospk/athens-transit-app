// HTTP access to the athens-transit backend (contract: athens-transit-map/docs/CONTRACT.md).
// Live data comes from transit.haroldpoi.dev, static data from the backend's GitHub Pages, and the
// trip index (every stop with the lines that stop there) from the web app's trips.json.

import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;

import '../core/city.dart';
import '../core/geo.dart';
import '../core/models.dart';
import '../core/muni.dart';
import '../core/quality.dart';
import '../core/rail.dart';
import '../core/stats.dart';
import 'cache.dart';

// The three URLs Athens uses stay where the other code imports them from: city.dart holds them.
export '../core/city.dart' show apiBase, staticBase, tripsUrl;

const metroUrl = 'https://bus.haroldpoi.dev/metro.json'; // metro, ISAP, tram: STASY GTFS + OSM tracks
const statsBase = 'https://raw.githubusercontent.com/angelospk/staseis-rt/stats/v1';
const statsUrl = '$statsBase/latest.json'; // newest day, once a day
const pushBase = 'https://push.haroldpoi.dev';
const railUrl = 'https://railway.gov.gr/api/public'; // suburban rail boards (docs/research/rail-data.md)
// The web's feedback endpoint (athens-transit-map docs/feedback/Code.gs: a Google Apps Script that writes a
// Sheet row). Public: the web's bundle carries it too. App reports come without the web's bot check.
const feedbackUrl =
    'https://script.google.com/macros/s/AKfycbzZH84suueqVGCinNzSDdd8oCplE2_w3jH8xkXB2GZ21TgS6U1tvQll0qmXFzdl2GezWw/exec';
const municipalUrl = '$apiBase/v2/municipal'; // «Δημοτικά»: municipal routes and stops (OSM, ODbL)
const muniTimesUrl = 'https://staseis.gr/municipal-times.json'; // the timetables the web checked, built with it
typedef MuniData = ({Municipal data, List<MuniCard> cards});

const placesUrl = 'https://photon.komoot.io/api/'; // OSM geocoder: addresses, areas, shops, landmarks

// Photon answers 403 to the default "Dart/x (dart:io)" agent.
const _ua = {'user-agent': 'athens-transit (github.com/angelospk/athens-transit-app)'};

final _dateRe = RegExp(r'^\d{4}-\d{2}-\d{2}$'); // a day file name

typedef Place = ({String name, String detail, double lat, double lon});

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
  Api({http.Client? client, DiskCache? cache, this.city = City.athens})
      : _client = client ?? http.Client(),
        _cache = cache ?? DiskCache();

  final http.Client _client;
  final DiskCache _cache;
  final City city;

  // One disk cache for every city: Athens keeps the file names it had, the others get their own.
  String _key(String key) => city == City.athens ? key : '${city.id}_$key';

  Future<void> clearCache() => _cache.clear();

  /// Feedback to the web's Apps Script. It answers a POST with a redirect to its reply (Dart does not follow
  /// it for a POST): the reply must say {ok: true}. false on any failure.
  Future<bool> sendFeedback({required String text, required String version, required String page, required String ua}) async {
    try {
      final body = jsonEncode({'text': text.trim(), 'version': version, 'page': page, 'ua': ua});
      var r = await _client.post(Uri.parse(feedbackUrl), headers: {..._ua, 'content-type': 'text/plain'}, body: body).timeout(const Duration(seconds: 20));
      final loc = r.headers['location'];
      if (r.statusCode >= 300 && r.statusCode < 400 && loc != null) {
        r = await _client.get(Uri.parse(loc), headers: _ua).timeout(const Duration(seconds: 20));
      }
      return r.statusCode == 200 && (jsonDecode(r.body) as Map?)?['ok'] == true;
    } catch (_) {
      return false;
    }
  }

  Future<dynamic> _get(String url) async {
    final r = await _client.get(Uri.parse(url), headers: _ua).timeout(const Duration(seconds: 15));
    if (r.statusCode != 200) throw ApiError(r.statusCode, url);
    return jsonDecode(utf8.decode(r.bodyBytes));
  }

  // Static files change only with a new GTFS: serve the disk copy at once and refresh it behind.
  Future<dynamic> _static(String key, String url) async {
    final k = _key(key);
    final saved = await _cache.read(k);
    if (saved != null) {
      _get(url).then((j) => _cache.write(k, j)).ignore();
      return saved;
    }
    final j = await _get(url);
    await _cache.write(k, j);
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

  Future<List<LineInfo>> lines() => _once('lines', () => _static('lines', '${city.static}/lines.json').then(parseLines));

  // A new day every day: the network first (each time the screen opens), the disk copy only without one.
  Future<DayStats> stats() async {
    Object? raw;
    try {
      raw = await _get(statsUrl);
      await _cache.write(_key('stats'), raw);
    } catch (_) {
      raw = await _cache.read(_key('stats'));
      if (raw == null) rethrow;
    }
    final j = raw as Map<String, dynamic>;
    if (j['version'] != 1 || (j['hours'] as List?)?.length != 24) throw const FormatException('stats: unknown format');
    return DayStats.fromJson(j);
  }

  // The newest complete stored days, oldest first. A day file never changes, so a saved copy is not
  // fetched again; a missing, broken or partial file is left out.
  Future<List<DayStats>> storedDays({int max = longDays}) async {
    final index = await _get('$statsBase/index.json');
    final listed = index is Map<String, dynamic> ? index['days'] : null;
    if (listed is! List) throw const FormatException('stats: unknown index format');
    final dates = [for (final d in listed) if (d is String && _dateRe.hasMatch(d)) d]..sort();
    final newest = dates.length > max ? dates.sublist(dates.length - max) : dates;
    final days = await Future.wait(newest.map(_storedDay));
    return [for (final d in days) ?d];
  }

  // A day file as docs/API.md describes it: null when it is missing, broken or partial.
  Future<DayStats?> _storedDay(String date) async {
    final key = _key('stats_day_$date');
    Object? j = await _cache.read(key);
    if (j == null) {
      try {
        j = await _get('$statsBase/days/$date.json');
        await _cache.write(key, j).catchError((_) {}); // a failed save must not fail the fetch
      } on ApiError catch (e) {
        if (e.status == 404) return null;
        rethrow;
      } on FormatException {
        return null; // a malformed day file is skipped, not fatal
      }
    }
    if (j is! Map<String, dynamic> || !validDay(j, date)) return null;
    final d = DayStats.fromJson(j);
    return complete(d) ? d : null;
  }

  // The line card's quality pill reads the day files of the city (Athens in v1 itself, Thessaloniki in v1/thessaloniki).
  // As the web's quality.ts: a day file is fetched once per session and shared by every card (a written day file never
  // changes); a missing one is asked again after an hour; a failed fetch on the next call.
  final _dayFiles = <String, _DayEntry>{};

  Future<QualityDay?> dayFile(String date, {DateTime? now}) {
    final nowMs = (now ?? DateTime.now()).millisecondsSinceEpoch;
    final base = city == City.athens ? statsBase : '$statsBase/${city.id}';
    final url = '$base/days/$date.json';
    final hit = _dayFiles[url];
    if (hit != null && (hit.found || nowMs - hit.at < 3600000)) return hit.load;
    Future<QualityDay?> fetch() async {
      try {
        final j = await _get(url);
        return j is Map<String, dynamic> && j['version'] == 1 && j['date'] == date ? QualityDay.fromJson(j) : null;
      } on ApiError catch (e) {
        if (e.status == 404) return null;
        rethrow;
      }
    }

    late final _DayEntry entry;
    entry = _DayEntry(nowMs, fetch().then<QualityDay?>((d) {
      entry.found = d != null;
      return d;
    }, onError: (Object _) {
      if (identical(_dayFiles[url], entry)) _dayFiles.remove(url);
      return null;
    }));
    return (_dayFiles[url] = entry).load;
  }

  /// The day the pill shows: yesterday's file, else (only then fetched) the day before's.
  Future<({QualityDay day, String word, String date})?> shownDay({DateTime? now}) async {
    final t = now ?? DateTime.now().toUtc();
    final y = await dayFile(daysAgo(t, 1), now: t);
    final p = pickDay(y, y != null ? null : await dayFile(daysAgo(t, 2), now: t));
    return p == null ? null : (day: p.day, word: p.word, date: daysAgo(t, p.back));
  }

  Future<TripIndex> trips() => _once('trips', () => _static('trips', city.trips).then((j) => TripIndex.fromJson(j)));

  Future<LineStatic> lineStatic(String line) => _once('line_$line',
      () => _static('line_$line', '${city.static}/lines/${Uri.encodeComponent(line)}.json').then((j) => LineStatic.fromJson(j)));

  /// The municipal lines, one card each, with their timetables; null while the backend has no routes.
  /// A timetable file that fails to load leaves the lines without times, never without the lines.
  Future<MuniData?> muni() => _once('muni', () async {
        final d = parseMunicipal(await _static('municipal', '${city.api}/v2/municipal'));
        if (d == null) return null;
        final t = await _static('muni_times', muniTimesUrl).then(parseMuniTimes).catchError((_) => const <MuniTable>[]);
        return (data: d, cards: muniCards(d, t));
      });

  // GeoJSON-ready raw data: {lines: [{id, name, color, paths: [[[lon, lat]...]...]}], stations: [...]}.
  Future<Map<String, dynamic>> metro() => _once('metro', () async => (await _static('metro', metroUrl)) as Map<String, dynamic>);

  Future<LineLive> live(String line) async {
    final j = await _get('${city.api}/v1/lines/${Uri.encodeComponent(line)}');
    await _cache.write(_key('live_$line'), j).catchError((_) {}); // a failed save must not fail the fetch
    return LineLive.fromJson(j);
  }

  // The last live copy of a line, for the offline estimate.
  Future<LineLive?> savedLive(String line) async {
    final j = await _cache.read(_key('live_$line'));
    return j == null ? null : LineLive.fromJson(j);
  }

  Future<VehicleTile> tile(int z, int x, int y) async {
    final j = await _get('${city.api}/v1/vehicles/tiles/$z/$x/$y');
    return VehicleTile(
      updatedAt: j['updated_at'] as int,
      nextUpdateAt: j['next_update_at'] as int,
      vehicles: [for (final v in j['vehicles'] as List) Vehicle.fromJson(v as Map<String, dynamic>)],
    );
  }

  // Places and addresses in the city that match the text, nearest to the centre first.
  Future<List<Place>> places(String q) async {
    final u = Uri.parse(placesUrl).replace(queryParameters: {
      'q': q,
      'limit': '6',
      'lat': '${city.centre.$1}',
      'lon': '${city.centre.$2}',
      'bbox': city.placesBox,
    });
    final j = await _get(u.toString()) as Map<String, dynamic>;
    final out = <Place>[];
    for (final f in j['features'] as List? ?? const []) {
      final p = f['properties'] as Map<String, dynamic>;
      final c = f['geometry']['coordinates'] as List;
      final street = [p['street'], p['housenumber']].whereType<String>().join(' ');
      final name = p['name'] as String? ?? street;
      if (name.isEmpty) continue;
      final detail = [if (street != name) street, p['locality'] ?? p['district'] ?? p['city']].whereType<String>().where((x) => x.isNotEmpty).join(', ');
      final at = ((c[1] as num).toDouble(), (c[0] as num).toDouble());
      // OSM often has one place twice (node and way); two shops of a chain are further apart.
      if (out.any((o) => o.name == name && o.detail == detail && distM((o.lat, o.lon), at) < 50)) continue;
      out.add((name: name, detail: detail, lat: at.$1, lon: at.$2));
    }
    return out;
  }

  // Suburban stations and lines, shipped with the app (assets/suburban.json).
  Future<Suburban> suburban() =>
      _once('suburban', () async => Suburban.fromJson(jsonDecode(await rootBundle.loadString('assets/suburban.json')) as Map<String, dynamic>));

  // The next trains at a suburban station, live from railway.gov.gr (scheduled time, expected time, delay).
  Future<List<RailDeparture>> railDepartures(String stationId, {int limit = 12}) async =>
      parseRailDepartures(await _get('$railUrl/stations/${Uri.encodeComponent(stationId)}/departures?limit=$limit'));

  // A line's timetable for today, by direction (backend, OASA GTFS): null until the backend serves it.
  // The timetable for the stops' "not started yet" rows: kept 10 minutes per line, failures too.
  final _schedules = <String, (int, Future<Map<String, dynamic>?>)>{};
  Future<Map<String, dynamic>?> cachedSchedule(String line) {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final hit = _schedules[line];
    if (hit != null && now - hit.$1 < 600) return hit.$2;
    final f = lineSchedule(line).catchError((Object _) => null);
    _schedules[line] = (now, f);
    return f;
  }

  Future<Map<String, dynamic>?> lineSchedule(String line) async {
    try {
      return (await _get('${city.api}/v1/lines/${Uri.encodeComponent(line)}/schedule')) as Map<String, dynamic>;
    } on ApiError catch (e) {
      if (e.status == 404 || e.status == 503) return null;
      rethrow;
    }
  }

  // Metro and tram timetable at a station (backend, STASY GTFS): null until the backend serves it.
  Future<Map<String, dynamic>?> stasyDepartures(String stop) async {
    try {
      return (await _get('${city.api}/v1/rail/stasy/departures?stop=${Uri.encodeQueryComponent(stop)}&n=4')) as Map<String, dynamic>;
    } on ApiError catch (e) {
      if (e.status == 404 || e.status == 503) return null;
      rethrow;
    }
  }

  Future<Map<String, dynamic>> status() async => (await _get('${city.api}/v1/status')) as Map<String, dynamic>;
}

class _DayEntry {
  _DayEntry(this.at, this.load);
  final int at; // ms epoch of the ask
  final Future<QualityDay?> load;
  bool found = false;
}

class VehicleTile {
  VehicleTile({required this.updatedAt, required this.nextUpdateAt, required this.vehicles});
  final int updatedAt, nextUpdateAt;
  final List<Vehicle> vehicles;
}
