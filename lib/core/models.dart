import 'geo.dart';

double? _d(Object? x) => x is num ? x.toDouble() : null;
int? _i(Object? x) => x is num ? x.round() : null;
Pt _pt(Object? x) {
  final l = x as List;
  return ((l[0] as num).toDouble(), (l[1] as num).toDouble());
}

List<Pt> _pts(Object? x) => [for (final p in (x as List? ?? const [])) _pt(p)];

class LineInfo {
  final String id, name, nameEn, color, textColor, kind;
  const LineInfo({
    required this.id,
    required this.name,
    this.nameEn = '',
    this.color = '#1a73e8',
    this.textColor = '#ffffff',
    this.kind = 'bus',
  });

  factory LineInfo.fromJson(Map<String, dynamic> j) => LineInfo(
        id: j['id'] as String,
        name: (j['name'] as String?) ?? '',
        nameEn: (j['name_en'] as String?) ?? '',
        color: (j['color'] as String?) ?? '#1a73e8',
        textColor: (j['text_color'] as String?) ?? '#ffffff',
        kind: (j['kind'] as String?) ?? 'bus',
      );
}

/// Parses lines.json ({"lines": [...]}) or a bare list.
List<LineInfo> parseLines(dynamic json) {
  final list = json is Map ? json['lines'] as List? : json as List?;
  return [for (final l in list ?? const []) LineInfo.fromJson(l as Map<String, dynamic>)];
}

class Variant {
  final String headsign;
  final int direction;
  final List<Pt> shape;
  final List<String> stops;
  const Variant({required this.headsign, required this.direction, required this.shape, required this.stops});

  factory Variant.fromJson(Map<String, dynamic> j) => Variant(
        headsign: (j['headsign'] as String?) ?? '',
        direction: _i(j['direction']) ?? 0,
        shape: _pts(j['shape']),
        stops: [for (final s in (j['stops'] as List? ?? const [])) s as String],
      );
}

class StopInfo {
  final String name;
  final double lat, lon;
  const StopInfo({required this.name, required this.lat, required this.lon});

  factory StopInfo.fromJson(Map<String, dynamic> j) => StopInfo(
        name: (j['name'] as String?) ?? '',
        lat: (j['lat'] as num).toDouble(),
        lon: (j['lon'] as num).toDouble(),
      );
}

class LineStatic {
  final String id;
  final Map<String, Variant> variants;
  final Map<String, StopInfo> stops;
  final Map<String, List<double>> _offsets = {};

  LineStatic({required this.id, required this.variants, required this.stops});

  factory LineStatic.fromJson(Map<String, dynamic> j) => LineStatic(
        id: j['id'] as String,
        variants: {
          for (final e in (j['variants'] as Map? ?? const {}).entries)
            e.key as String: Variant.fromJson(e.value as Map<String, dynamic>),
        },
        stops: {
          for (final e in (j['stops'] as Map? ?? const {}).entries)
            e.key as String: StopInfo.fromJson(e.value as Map<String, dynamic>),
        },
      );

  /// Metres along the variant's shape of each of its stops (cached).
  List<double> offsetsFor(String variantId) {
    final cached = _offsets[variantId];
    if (cached != null) return cached;
    final v = variants[variantId];
    if (v == null) return const [];
    final pts = <Pt>[];
    for (final id in v.stops) {
      final s = stops[id];
      pts.add(s != null ? (s.lat, s.lon) : (pts.isNotEmpty ? pts.last : (v.shape.isNotEmpty ? v.shape.first : (0.0, 0.0))));
    }
    return _offsets[variantId] = v.shape.length < 2 ? List.filled(pts.length, 0.0) : stopOffsets(v.shape, pts);
  }
}

class Vehicle {
  final String id;
  final String? line;
  final double lat, lon;
  final double? bearing;
  final int positionAt;
  final String? routeCode, variant, tripId, tripLabel, nextStopId;
  final int? delayS;
  final double? speed;
  final List<Pt>? path, pathBeyond;
  final List<double>? pathStops;
  final List<double?>? pathSpeeds;

  const Vehicle({
    required this.id,
    this.line,
    required this.lat,
    required this.lon,
    this.bearing,
    required this.positionAt,
    this.routeCode,
    this.variant,
    this.tripId,
    this.tripLabel,
    this.delayS,
    this.nextStopId,
    this.speed,
    this.path,
    this.pathBeyond,
    this.pathStops,
    this.pathSpeeds,
  });

  factory Vehicle.fromJson(Map<String, dynamic> j) => Vehicle(
        id: '${j['id']}',
        line: j['line'] as String?,
        lat: _d(j['lat']) ?? 0,
        lon: _d(j['lon']) ?? 0,
        bearing: _d(j['bearing']),
        positionAt: _i(j['position_at']) ?? 0,
        routeCode: j['route_code'] as String?,
        variant: j['variant'] as String?,
        tripId: j['trip_id'] as String?,
        tripLabel: j['trip_label'] as String?,
        delayS: _i(j['delay_s']),
        nextStopId: j['next_stop_id'] as String?,
        speed: _d(j['speed']),
        path: j['path'] == null ? null : _pts(j['path']),
        pathBeyond: j['path_beyond'] == null ? null : _pts(j['path_beyond']),
        pathStops: j['path_stops'] == null ? null : [for (final x in j['path_stops'] as List) (x as num).toDouble()],
        pathSpeeds: j['path_speeds'] == null ? null : [for (final x in j['path_speeds'] as List) _d(x)],
      );
}

class LineLive {
  final String line;
  final int updatedAt, nextUpdateAt;
  final List<Vehicle> vehicles;

  const LineLive({required this.line, required this.updatedAt, required this.nextUpdateAt, required this.vehicles});

  factory LineLive.fromJson(Map<String, dynamic> j) => LineLive(
        line: (j['line'] as String?) ?? '',
        updatedAt: _i(j['updated_at']) ?? 0,
        nextUpdateAt: _i(j['next_update_at']) ?? 0,
        vehicles: [for (final v in (j['vehicles'] as List? ?? const [])) Vehicle.fromJson(v as Map<String, dynamic>)],
      );
}

/// The planner's stop index: stops [name, lat, lon], and per line, per variant, its stops as indexes into `s`.
class TripIndex {
  final String v;
  final List<(String, double, double)> s;
  final Map<String, Map<String, List<int>>> l;

  const TripIndex({required this.v, required this.s, required this.l});

  factory TripIndex.fromJson(Map<String, dynamic> j) => TripIndex(
        v: (j['v'] as String?) ?? '',
        s: [
          for (final e in (j['s'] as List? ?? const []))
            ((e as List)[0] as String, (e[1] as num).toDouble(), (e[2] as num).toDouble()),
        ],
        l: {
          for (final e in (j['l'] as Map? ?? const {}).entries)
            e.key as String: {
              for (final ve in (e.value as Map).entries)
                ve.key as String: [for (final k in ve.value as List) (k as num).toInt()],
            },
        },
      );
}
