// Suburban rail (Προαστιακός): the stations and lines of assets/suburban.json (railway.gov.gr
// corridors, places from OpenStreetMap, built once; see docs/research/rail-data.md), and the live
// departure boards of railway.gov.gr.

import 'geo.dart';
import 'nearby.dart';

class RailStation {
  RailStation({required this.id, required this.name, required this.en, required this.lat, required this.lon, required this.corridors});
  final String id, name, en;
  final double lat, lon;
  final List<String> corridors;
}

class Corridor {
  Corridor({required this.id, required this.name, required this.color, required this.path, required this.stations});
  final String id, name, color; // color: ours, the API has none
  final List<Pt> path;
  final List<String> stations; // in line order, from the start of `name`
}

class Suburban {
  Suburban({required this.corridors, required this.stations});
  final Map<String, Corridor> corridors;
  final Map<String, RailStation> stations;

  factory Suburban.fromJson(Map<String, dynamic> j) => Suburban(
        corridors: {
          for (final e in (j['corridors'] as Map).entries)
            e.key as String: Corridor(
              id: e.key as String,
              name: e.value['name'] as String,
              color: e.value['color'] as String,
              path: [for (final p in e.value['path'] as List) ((p[0] as num).toDouble(), (p[1] as num).toDouble())],
              stations: [for (final s in e.value['stations'] as List) s as String],
            ),
        },
        stations: {
          for (final s in j['stations'] as List)
            s['id'] as String: RailStation(
              id: s['id'] as String,
              name: s['name'] as String,
              en: s['en'] as String? ?? '',
              lat: (s['lat'] as num).toDouble(),
              lon: (s['lon'] as num).toDouble(),
              corridors: [for (final c in s['corridors'] as List) c as String],
            ),
        },
      );

  // Accents, case and the saint's abbreviation ignored: the board writes "Άγιοι Ανάργυροι" for our
  // "Αγ. Ανάργυροι".
  RailStation? byName(String name) {
    final f = _key(name);
    return stations.values.where((s) => _key(s.name) == f).firstOrNull;
  }

  static String _key(String s) =>
      fold(_aliases[s] ?? s)
          .replaceAll(RegExp(r'\(.*?\)'), '').replaceAll('.', ' ').replaceFirst(RegExp(r'^αγι(οι|οσ|ος|α|ου) '), 'αγ ').replaceAll(RegExp(r'\s+'), ' ').trim();

  // The board gives only the next stop of a train: its end is the end of each corridor through both
  // stations in that direction (a short run, e.g. Άνω Λιόσια–Αεροδρόμιο, still reads as the line's end).
  Set<String> towards(String stationId, String next) {
    final out = <String>{};
    final n = byName(next);
    if (n == null) return out;
    for (final c in corridors.values) {
      final i = c.stations.indexOf(stationId), k = c.stations.indexOf(n.id);
      if (i < 0 || k < 0 || i == k) continue;
      final end = k > i ? c.stations.last : c.stations.first;
      out.add(stations[end]!.name);
    }
    return out;
  }
}

// The board's names that our table (railway.gov.gr's station list) spells otherwise.
const _aliases = {
  'Σιδηροδρομικό Κέντρο Αχαρνών': 'Σιδηροδρομικός Κέντρο Αχαρνών',
  'Ρέντης': 'Άγιος Ιωάννης Ρέντης',
  'Πύργος Βασιλίσσης': 'Πύργος Βαιλίσσης',
};

class RailDeparture {
  RailDeparture({required this.train, required this.next, required this.scheduled, required this.expected, required this.platform, required this.status, required this.delayMin});
  final String train, next, status; // status: scheduled, in_progress, delayed, completed, cancelled
  final DateTime scheduled, expected; // UTC
  final String? platform;
  final int? delayMin;
  bool get cancelled => status == 'cancelled';
}

/// `GET /api/public/stations/{id}/departures` of railway.gov.gr.
List<RailDeparture> parseRailDepartures(dynamic j) => [
      for (final d in (j is Map ? j['departures'] as List? : null) ?? const [])
        if (DateTime.tryParse(d['scheduledTime'] as String? ?? '') case final at?)
          RailDeparture(
            train: '${d['trainNumber'] ?? ''}'.trim(),
            next: d['to'] as String? ?? '',
            scheduled: at.toUtc(),
            expected: (DateTime.tryParse(d['actualTime'] as String? ?? '') ?? at).toUtc(),
            platform: d['platform'] as String?,
            status: d['status'] as String? ?? 'scheduled',
            delayMin: (d['delay'] as num?)?.round(),
          ),
    ];
