// Live quality levels of contract rev 23 (athens-transit-rt docs/QUALITY.md; port of the web's src/lib/liveQuality.ts,
// v0.2.38): the level of each vehicle of a line, the slow segments of its route, and the words for them.
// Athens and Thessaloniki only (OASA buses and trolleys), which are the app's only cities. One scale for every
// level: green, yellow, red, grey. Pure: no widgets, no network.

import 'dart:math';

import 'geo.dart';
import 'models.dart';

enum QualityLevel {
  normal,
  worse,
  muchWorse,
  unknown;

  /// The API's word; a value this version does not know is shown as unknown, as the contract asks.
  static QualityLevel parse(Object? v) => switch (v) {
        'normal' => normal,
        'worse' => worse,
        'much_worse' => muchWorse,
        _ => unknown,
      };

  /// A level with a colour: not unknown.
  bool get live => this != unknown;
}

int? _int(Object? v) => v is num && v.isFinite ? v.toInt() : null;
double? _dbl(Object? v) => v is num && v.isFinite ? v.toDouble() : null;
String _native(String id) => id.substring(id.indexOf(':') + 1); // "oasa:52134" → "52134"

/// A vehicle's `quality` (contract rev 23).
class VehicleQuality {
  const VehicleQuality({required this.level, this.basis, this.gapS, this.usualHeadwayS, this.stop, this.bunched = false, this.early = false});
  final QualityLevel level;
  final String? basis; // 'headway' or 'schedule': the measure behind the level; null when there is none
  final int? gapS; // headway basis: the gap to the bus ahead at its last stop
  final int? usualHeadwayS;
  final String? stop;
  final bool bunched; // two buses together: the gap does not tell the wait
  final bool early;

  static VehicleQuality? tryParse(Object? j) => j is! Map
      ? null
      : VehicleQuality(
          level: QualityLevel.parse(j['level']),
          basis: j['basis'] is String ? j['basis'] as String : null,
          gapS: _int(j['gap_s']),
          usualHeadwayS: _int(j['usual_headway_s']),
          stop: j['stop'] is String ? j['stop'] as String : null,
          bunched: j['bunched'] == true,
          early: j['early'] == true,
        );
}

/// One pair of stops of one pattern, as the backend measured it.
class Segment {
  const Segment({required this.pattern, required this.from, required this.to, required this.level, this.ratio, required this.speed, this.usualSpeed, this.n = 0});
  final String pattern, from, to;
  final QualityLevel level;
  final double? ratio; // speed / usual speed
  final double speed; // m/s
  final double? usualSpeed; // m/s
  final int n; // measured runs

  static Segment? tryParse(Object? j) {
    if (j is! Map || j['pattern'] is! String || j['from'] is! String || j['to'] is! String) return null;
    final speed = _dbl(j['speed']);
    if (speed == null) return null;
    return Segment(
      pattern: j['pattern'] as String,
      from: j['from'] as String,
      to: j['to'] as String,
      level: QualityLevel.parse(j['level']),
      ratio: _dbl(j['ratio']),
      speed: speed,
      usualSpeed: _dbl(j['usual_speed']),
      n: _int(j['n']) ?? 0,
    );
  }
}

/// The live levels of one line: `/v2/lines/{id}/vehicles` (vehicles and segments).
class LineQuality {
  const LineQuality(this.vehicles, this.segments);

  /// By native vehicle id, as the map's vehicles are keyed. A vehicle without a `quality` object is present, null.
  final Map<String, VehicleQuality?> vehicles;
  final List<Segment> segments;

  /// Null when the body is not of the expected shape. A body without `segments` (an older backend) has none.
  static LineQuality? tryParse(Object? body) {
    final vs = body is Map ? body['vehicles'] : null;
    if (vs is! List) return null;
    final segs = (body as Map)['segments'];
    return LineQuality({
      for (final v in vs)
        if (v is Map && v['id'] is String) _native(v['id'] as String): VehicleQuality.tryParse(v['quality']),
    }, [if (segs is List) for (final s in segs) ?Segment.tryParse(s)]);
  }

  /// The level the map draws for a vehicle: null when this line's levels were not asked for or the vehicle is not
  /// in them, unknown when the vehicle has no level.
  QualityLevel? levelOf(String vehicleId) {
    if (!vehicles.containsKey(vehicleId)) return null;
    final q = vehicles[vehicleId];
    return q != null && q.level.live ? q.level : QualityLevel.unknown;
  }
}

typedef Phrase = ({String text, QualityLevel level});
const Phrase _dash = (text: '—', level: QualityLevel.unknown);

/// The vehicle row's words: the gap to the bus ahead, or the delay, in whole minutes. No quality object (an older
/// backend, a vehicle the list did not have) is null, and the caller keeps the delay text.
Phrase? vehiclePhrase(VehicleQuality? q, int? delayS) {
  if (q == null) return null;
  if (!q.level.live) return _dash;
  final level = q.level;
  switch (q.basis) {
    case 'headway':
      final gap = q.gapS;
      if (gap == null) return _dash;
      if (q.bunched) return (text: 'κολλητά', level: level);
      return (text: '${max(1, (gap / 60).round())}′ μετά', level: level);
    case 'schedule':
      if (delayS == null) return _dash;
      final m = delayS.abs() ~/ 60; // whole minutes; under one is still on time
      if (m == 0) return (text: 'στην ώρα', level: level);
      return (text: q.early || delayS < 0 ? 'νωρίτερα $m′' : '+$m′', level: level);
    default:
      return _dash;
  }
}

/// The gap's words: how much slower than usual, and the two speeds in km/h.
String gapText(QualityLevel level, double speed, double? usualSpeed) {
  final how = level == QualityLevel.muchWorse ? 'πολύ πιο αργό' : 'πιο αργό';
  final usual = usualSpeed == null ? '' : ', συνήθως ${(usualSpeed * 3.6).round()}';
  return '$how: ${(speed * 3.6).round()} km/h$usual';
}

/// The segment's words: the stops, how much slower than usual, and the two speeds in km/h.
String segmentText(String from, String to, QualityLevel level, double speed, double? usualSpeed) =>
    '$from → $to · ${gapText(level, speed, usualSpeed)}';

/// The metres of [shape] from [s0] to [s1] metres along it, as points (the ends cut inside their legs).
List<Pt> subLine(List<Pt> shape, double s0, double s1) {
  if (shape.length < 2 || s1 <= s0) return const [];
  final out = <Pt>[];
  var walked = 0.0;
  for (var i = 1; i < shape.length; i++) {
    final a = shape[i - 1], b = shape[i], len = distM(a, b);
    final from = walked, to = walked + len;
    walked = to;
    if (to < s0 || len == 0) continue;
    if (from > s1) break;
    Pt at(double s) {
      final k = ((s - from) / len).clamp(0.0, 1.0);
      return (a.$1 + (b.$1 - a.$1) * k, a.$2 + (b.$2 - a.$2) * k);
    }

    if (out.isEmpty) out.add(at(s0));
    out.add(at(min(s1, to)));
    if (to >= s1) break;
  }
  return [for (var i = 0; i < out.length; i++) if (i == 0 || out[i] != out[i - 1]) out[i]];
}

/// The slow segments of the drawn lines as halo features (a GeoJSON LineString each, under the route): only worse
/// and much_worse, cut from stop to stop. A segment of a pattern that is not drawn, or of stops that do not follow
/// each other in it, gets none; the same stop pair of two patterns is drawn once. [only]: the variants drawn per line
/// (null: all). [tips]: the words of each halo by feature id, for a tap.
({List<Object> features, Map<String, ({String text, QualityLevel level})> tips}) haloFeatures({
  required Map<String, LineStatic> statics,
  required Map<String, Set<String>?> only,
  required Map<String, List<Segment>> segs,
  required String Function(String) name,
}) {
  final features = <Object>[];
  final tips = <String, ({String text, QualityLevel level})>{};
  for (final e in segs.entries) {
    final st = statics[e.key];
    if (st == null || !only.containsKey(e.key)) continue;
    final visible = only[e.key];
    final seen = <String>{};
    for (final s in e.value) {
      if (s.level != QualityLevel.worse && s.level != QualityLevel.muchWorse) continue;
      final variant = _native(s.pattern), from = _native(s.from), to = _native(s.to);
      final v = st.variants[variant];
      if (v == null || (visible != null && !visible.contains(variant))) continue;
      final pair = '$from|$to';
      if (seen.contains(pair)) continue;
      final i = [for (var k = 0; k + 1 < v.stops.length; k++) if (v.stops[k] == from && v.stops[k + 1] == to) k].firstOrNull;
      final a = st.stops[from], b = st.stops[to];
      if (i == null || a == null || b == null) continue;
      final off = st.offsetsFor(variant);
      if (i + 1 >= off.length) continue;
      final pts = subLine(v.shape, off[i], off[i + 1]);
      if (pts.length < 2) continue;
      seen.add(pair);
      final id = 'hs|${features.length}';
      tips[id] = (text: segmentText(name(a.name), name(b.name), s.level, s.speed, s.usualSpeed), level: s.level);
      features.add({
        'type': 'Feature',
        'id': id,
        'properties': {'level': s.level == QualityLevel.muchWorse ? 'much_worse' : 'worse'},
        'geometry': {'type': 'LineString', 'coordinates': [for (final p in pts) [p.$2, p.$1]]},
      });
    }
  }
  return (features: features, tips: tips);
}
