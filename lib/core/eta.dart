import 'geo.dart';
import 'models.dart';

const maxFixAgeS = 120; // an older position says nothing about where the bus is now
const _fallbackSpeed = 4.2; // m/s
const _stepM = 200.0;
const _passedM = 30.0;

/// Stops left to the boarding stop stops[i], itself included (1 = the bus's next stop is yours), or
/// null: passed, unknown next stop, or an old fix. A next stop the variant passes twice (loops) says
/// nothing about which pass it is: null until the bus reaches another stop.
int? stopsLeft(List<String> stops, int i, Vehicle v, int nowS) {
  final next = v.nextStopId;
  if (next == null || next.isEmpty || !(nowS - v.positionAt <= maxFixAgeS) || i < 0 || i >= stops.length) return null;
  final k = stops.indexOf(next);
  if (k < 0 || k > i || stops.indexOf(next, k + 1) >= 0) return null;
  return i - k + 1;
}

/// Metres along the shape from [v] to stops[stopIndex] of its variant (negative once past it), or
/// null: unknown variant, off the route.
double? metresToStop(LineStatic st, Vehicle v, int stopIndex) {
  final vid = v.variant;
  final variant = vid == null ? null : st.variants[vid];
  if (vid == null || variant == null) return null;
  final offs = st.offsetsFor(vid);
  if (stopIndex < 0 || stopIndex >= offs.length) return null;
  final cands = projectCandidates(variant.shape, (v.lat, v.lon));
  if (cands.isEmpty) return null;

  var pool = cands;
  final next = v.nextStopId;
  final nextK = next == null ? -1 : variant.stops.indexOf(next);
  if (nextK >= 0) {
    final limit = offs[nextK] + _passedM;
    final ok = cands.where((c) => c.s <= limit).toList();
    // The latest leg before the next stop: the pass of a loop the bus is on.
    if (ok.isNotEmpty) pool = [ok.last];
  }
  var best = pool.first;
  for (final c in pool) {
    if (c.offM < best.offM) best = c;
  }

  return offs[stopIndex] - best.s;
}

/// The position alone puts [v] past stops[stopIndex]: every leg of the shape it could be on is past
/// the stop, so a shape that doubles back near the stop never counts (whatever next_stop_id says).
bool pastByPosition(LineStatic st, Vehicle v, int stopIndex) {
  final vid = v.variant;
  final variant = vid == null ? null : st.variants[vid];
  if (vid == null || variant == null) return false;
  final offs = st.offsetsFor(vid);
  if (stopIndex < 0 || stopIndex >= offs.length) return false;
  final cands = projectCandidates(variant.shape, (v.lat, v.lon));
  return cands.isNotEmpty && cands.every((c) => c.s - offs[stopIndex] > _passedM);
}

/// Seconds until [v] reaches stops[stopIndex] of its variant, or null (passed, unknown variant,
/// off the route).
int? etaSeconds(LineStatic st, Vehicle v, int stopIndex, int nowS) {
  final m = metresToStop(st, v, stopIndex);
  if (m == null || m < -_passedM) return null;
  var d = m < 0 ? 0.0 : m;

  final steps = v.pathSpeeds;
  final own = (v.speed ?? 0) > 0.5 ? v.speed! : _fallbackSpeed;
  var t = 0.0;
  var i = 0;
  while (d > 0) {
    final seg = d < _stepM ? d : _stepM;
    final step = steps != null && i < steps.length ? steps[i] : null;
    final sp = steps == null || i >= steps.length ? _fallbackSpeed : (step != null && step > 0.5 ? step : own);
    t += seg / sp;
    d -= seg;
    i++;
  }
  final left = t - (nowS - v.positionAt);
  // Only an old fix (the offline estimate) can run out this far: the bus has gone by.
  if (left < -maxFixAgeS) return null;
  return (left < 0 ? 0 : left).round();
}

class Arrival {
  final String line, variant, headsign, vehicleId;
  final int etaS;
  final int? stopsLeft, delayS;
  final int positionAt;
  const Arrival({
    required this.line,
    required this.variant,
    required this.headsign,
    required this.vehicleId,
    required this.etaS,
    required this.stopsLeft,
    required this.delayS,
    required this.positionAt,
  });
}

/// Live vehicles still before [stopId], soonest first.
List<Arrival> arrivalsAt(String stopId, Map<String, LineStatic> statics, Map<String, LineLive> lives, int nowS) {
  final out = <Arrival>[];
  for (final e in lives.entries) {
    final st = statics[e.key];
    if (st == null) continue;
    for (final v in e.value.vehicles) {
      final vid = v.variant;
      final variant = vid == null ? null : st.variants[vid];
      if (vid == null || variant == null) continue;
      final stops = variant.stops;
      final nextK = v.nextStopId == null ? 0 : stops.indexOf(v.nextStopId!);
      final i = stops.indexOf(stopId, nextK < 0 ? 0 : nextK);
      if (i < 0) continue;
      final eta = etaSeconds(st, v, i, nowS);
      if (eta == null) continue;
      out.add(Arrival(
        line: e.key,
        variant: vid,
        headsign: variant.headsign,
        vehicleId: v.id,
        etaS: eta,
        stopsLeft: stopsLeft(stops, i, v, nowS),
        delayS: v.delayS,
        positionAt: v.positionAt,
      ));
    }
  }
  out.sort((a, b) => a.etaS.compareTo(b.etaS));
  return out;
}
