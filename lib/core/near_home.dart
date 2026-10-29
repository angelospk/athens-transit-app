// The map's home sheet: the bus stops and the metro, tram and suburban stations nearest the user,
// nearest first, from data the app already holds (trips.json, metro.json, assets/suburban.json).

import 'dart:math';

import 'geo.dart';
import 'models.dart';
import 'nearby.dart';
import 'rail.dart';

enum NearKind { bus, metro, tram, rail }

/// A metro, ISAP or tram station (railId null), or a suburban station (railId: railway.gov.gr id).
class Station {
  const Station({required this.name, required this.lat, required this.lon, required this.lines, this.railId, List<String>? names})
      : names = names ?? const [];
  final String name;
  final List<String> names; // every name of a merged station: the backend's timetable knows each one
  final double lat, lon;
  final List<String> lines; // metro/tram line ids, or suburban corridor ids
  final String? railId;
}

class NearPlace {
  const NearPlace(
      {required this.kind, required this.name, required this.lat, required this.lon, required this.distM, required this.lines, this.railId, this.names = const []});
  final NearKind kind;
  final String name;
  final List<String> names; // a station's names (see Station.names); empty for a bus stop
  final double lat, lon, distM;
  final List<String> lines;
  final String? railId;
}

/// metro.json's stations; entries of one name within 150 m, or with the same lines within 100 m (one
/// station or interchange under two names: ΣΥΝΤΑΓΜΑ and Σύνταγμα (Κέντρο)), merge into the first.
List<Station> metroStations(Map<String, dynamic> j) {
  final out = <Station>[];
  for (final s in j['stations'] as List? ?? const []) {
    final name = s['name'] as String;
    final lat = (s['lat'] as num).toDouble(), lon = (s['lon'] as num).toDouble();
    final lines = [for (final l in s['lines'] as List? ?? const []) l as String];
    final set = lines.toSet();
    final i = out.indexWhere((o) {
      final d = distM((o.lat, o.lon), (lat, lon));
      return o.name == name && d <= 150 || d <= 100 && o.lines.toSet().containsAll(set) && set.containsAll(o.lines);
    });
    if (i < 0) {
      out.add(Station(name: name, lat: lat, lon: lon, lines: set.toList()..sort(), names: [name]));
    } else {
      final o = out[i];
      out[i] = Station(name: o.name, lat: o.lat, lon: o.lon, lines: {...o.lines, ...lines}.toList()..sort(), names: {...o.names, name}.toList());
    }
  }
  return out;
}

List<Station> suburbanStations(Suburban sub) => [
      for (final s in sub.stations.values)
        Station(name: s.name, lat: s.lat, lon: s.lon, lines: s.corridors.toSet().toList(), railId: s.id, names: [s.name]),
    ];

NearKind _kindOf(Station s) => s.railId != null
    ? NearKind.rail
    : s.lines.isNotEmpty && s.lines.every((l) => l.startsWith('T'))
        ? NearKind.tram
        : NearKind.metro;

/// The places within the first radius that holds at least [enough] of them (else the last radius),
/// nearest first, at most [max].
List<NearPlace> nearPlaces(TripIndex? ix, List<Station> stations, Pt me,
    {int max = 8, int enough = 3, List<double> radii = const [600, 1200, 2500]}) {
  var out = <NearPlace>[];
  for (final r in radii) {
    out = [
      if (ix != null)
        for (final s in nearbyStops(ix, me, radiusM: r, max: max))
          NearPlace(kind: NearKind.bus, name: s.name, lat: s.lat, lon: s.lon, distM: s.distM, lines: s.lines),
      for (final s in stations)
        if (distM(me, (s.lat, s.lon)) case final d when d <= r)
          NearPlace(kind: _kindOf(s), name: s.name, lat: s.lat, lon: s.lon, distM: d, lines: s.lines, railId: s.railId, names: s.names),
    ]..sort((a, b) => a.distM.compareTo(b.distM));
    if (out.length >= enough) break;
  }
  return out.take(max).toList();
}

/// The user's saved lines that stop at a bus stop, in the stop's order.
List<String> myLinesHere(NearPlace p, Iterable<String> myLines) {
  if (p.kind != NearKind.bus) return const [];
  final mine = myLines.toSet();
  return [for (final l in p.lines) if (mine.contains(l)) l];
}

/// Minutes on foot: 80 m a minute, streets 1.25 × the straight line.
int walkMin(double m) => max(1, (m * 1.25 / 80).round());

/// "40 μ." to the nearest 10 m below 1 km, "1,3 χλμ." above.
String distLabel(double m) {
  final r = (m / 10).round() * 10;
  return r < 1000 ? '$r μ.' : '${(m / 1000).toStringAsFixed(1).replaceAll('.', ',')} χλμ.';
}

class StationDep {
  const StationDep({required this.line, required this.towards, required this.inS, this.color});
  final String line, towards;
  final int inS;
  final String? color; // "#rrggbb" from the timetable
}

/// Metro/tram: the next departure of each line and direction, soonest first, from the backend's
/// timetable answers for each name of a station; [elapsedS] since the fetch is taken off. A run that
/// ends at the station itself (its headsign one of [here]) leaves nobody from it and is left out.
List<StationDep> nextByDirection(List<List<Map<String, dynamic>>> answers, {required int elapsedS, int max = 6, Iterable<String> here = const []}) {
  final first = <String, StationDep>{};
  final ends = {for (final n in here) fold(n)};
  for (final deps in answers) {
    for (final d in deps) {
      final inS = ((d['in_s'] as num?) ?? 0).toInt() - elapsedS;
      if (inS < 0 || ends.contains(fold('${d['headsign'] ?? ''}'))) continue;
      final dep = StationDep(line: '${d['line'] ?? ''}', towards: '${d['headsign'] ?? ''}', inS: inS, color: d['route_color'] as String?);
      final k = '${dep.line}|${dep.towards}';
      if (first[k] == null || inS < first[k]!.inS) first[k] = dep;
    }
  }
  return (first.values.toList()..sort((a, b) => a.inS.compareTo(b.inS))).take(max).toList();
}

/// Suburban: the next trains that have not left and are not completed, soonest first.
List<RailDeparture> nextTrains(List<RailDeparture> all, DateTime now, {int max = 2}) => (all
        .where((d) => d.status != 'completed' && !d.expected.isBefore(now))
        .toList()
      ..sort((a, b) => a.expected.compareTo(b.expected)))
    .take(max)
    .toList();

/// nearPlaces for the home sheet, searched again only when the position, the trip index or the stations
/// change: the sheet is built every frame while it is dragged. It keeps every place 2,5 km around, so
/// the stop of my lines and the station further off are found (core/home_sheet.dart homeGroups keeps 8).
class NearMemo {
  TripIndex? _ix;
  List<Station> _stations = const [];
  Pt? _me;
  List<NearPlace>? _out;

  List<NearPlace> places(TripIndex? ix, List<Station> stations, Pt me) {
    final same = _out != null &&
        identical(ix, _ix) &&
        me == _me &&
        stations.length == _stations.length &&
        Iterable<int>.generate(stations.length).every((i) => identical(stations[i], _stations[i]));
    if (!same) {
      _ix = ix;
      _stations = List.of(stations);
      _me = me;
      _out = nearPlaces(ix, stations, me, max: 100000, radii: const [2500]);
    }
    return _out!;
  }
}
