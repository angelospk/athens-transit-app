import 'geo.dart';
import 'models.dart';
import 'nearby.dart' show fold;

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

/// Of the ETAs of a bus's next stops (in order), the first to show. An old fix makes the stops the bus
/// has passed since read 0 ("τώρα") or null: of those at the front only the last 0 stays, the stop the
/// bus is at.
int firstUpcoming(List<int?> etas) {
  var k = 0;
  while (k < etas.length && (etas[k] ?? 0) == 0) {
    k++;
  }
  // etas[0..k) are all 0 or null: keep the last of them if it is a 0.
  return k > 0 && etas[k - 1] == 0 ? k - 1 : k;
}

/// Of the same ETAs, the first stop a rider can still get off at: the stop the bus is at is too late.
int firstAlight(List<int?> etas) {
  final k = firstUpcoming(etas);
  return k < etas.length && etas[k] == 0 ? k + 1 : k;
}

/// Stops between the buses of one direction, from the front bus back; positions are the indexes of
/// each bus's next stop in the variant.
List<int> busGaps(List<int> positions) {
  final p = [...positions]..sort((a, b) => b.compareTo(a));
  return [for (var i = 1; i < p.length; i++) p[i - 1] - p[i]];
}

/// The index of a gap more than twice the median (buses bunched behind it), or null.
int? bigGap(List<int> gaps) {
  if (gaps.length < 2) return null;
  final m = ([...gaps]..sort())[gaps.length ~/ 2];
  var best = -1;
  for (var i = 0; i < gaps.length; i++) {
    if (gaps[i] > 2 * m && (best < 0 || gaps[i] > gaps[best])) best = i;
  }
  return best < 0 ? null : best;
}

/// Metres to the first 200 m step ahead whose typical speed (path_speeds, m/s) is under 10 km/h,
/// within the next 2 km; null if none.
int? slowAheadM(List<double?>? steps) {
  if (steps == null) return null;
  for (var i = 0; i < steps.length && i < 10; i++) {
    final v = steps[i];
    if (v != null && v * 3.6 < 10) return i * 200;
  }
  return null;
}

/// The timetable direction (backend /v1/lines/{id}/schedule) that matches [v], or null when none fits
/// for sure. A GTFS headsign names both ends ("start - via - end"), and the timetable direction is named
/// after its end. Names are folded and lose notes in brackets ("(Προσωρινή λόγω έργων)"). The only
/// direction that matches that end (either contains the other), else the only one with its last word
/// ("Α. ΠΑΤΗΣΙΑ" = "ΑΝΩ ΠΑΤΗΣΙΑ"), else the only one with the same whole name. A direction that also
/// fits the start is never the end's (unless a loop starts where it ends). Never by direction number:
/// every GTFS variant has 0.
Map<String, dynamic>? directionFor(Map<String, dynamic> schedule, Variant v) {
  final dirs = [for (final d in schedule['directions'] as List? ?? const []) d as Map<String, dynamic>];
  String plain(String s) => fold(s).replaceAll(RegExp(r'\([^)]*\)?'), ' ').replaceAll(RegExp(r'\s+'), ' ').trim();
  String h(Map<String, dynamic> d) => plain('${d['headsign'] ?? ''}');
  Map<String, dynamic>? only(bool Function(String h) fits) {
    final hit = dirs.where((d) => h(d).isNotEmpty && fits(h(d))).toList();
    return hit.length == 1 ? hit.single : null;
  }

  final parts = v.headsign.split(' - ');
  final end = plain(parts.last), start = plain(parts.first);
  List<String> words(String s) => s.split(RegExp(r'[ .]'));
  bool near(String x, String place) =>
      place.isNotEmpty && (x.contains(place) || place.contains(x) || (words(place).last.length >= 4 && words(x).contains(words(place).last)));
  final twoEnds = parts.length >= 2 && start != end; // a loop starts where it ends
  bool isStart(String x) => twoEnds && (x.contains(start) || start.contains(x));
  return (end.isEmpty ? null : only((x) => (x.contains(end) || end.contains(x)) && !isStart(x))) ??
      only((x) => twoEnds && near(x, end) && !near(x, start)) ?? // the start shares the word: not it
      only((x) => x == plain(v.headsign));
}

/// The departures ("HH:MM") of [directionFor].
List<String>? departuresFor(Map<String, dynamic> schedule, Variant v) {
  final d = directionFor(schedule, v);
  return d == null ? null : [for (final x in d['departures'] as List? ?? const []) '${(x as Map)['t'] ?? ''}'];
}

/// The last run of the day of the variant's timetable direction: its departure ("HH:MM", "24:40"
/// after midnight) and when it passes stop [i] of [variantId], in seconds since today's Athens
/// midnight (past 24 h after it). Same run time as [plannedEtas].
({String t, int atStopS})? lastRun(Map<String, dynamic> schedule, LineStatic st, String variantId, int i, {double speedMps = 4.2}) {
  final v = st.variants[variantId];
  final deps = v == null ? null : departuresFor(schedule, v);
  final offs = st.offsetsFor(variantId);
  if (deps == null || i < 0 || i >= offs.length) return null;
  ({String t, int s})? last;
  for (final t in deps) {
    final p = t.split(':');
    final h = p.length >= 2 ? int.tryParse(p[0]) : null, m = p.length >= 2 ? int.tryParse(p[1]) : null;
    if (h == null || m == null) continue;
    final s = h * 3600 + m * 60;
    if (last == null || s > last.s) last = (t: t, s: s);
  }
  if (last == null) return null;
  return (t: last.t, atStopS: (last.s + (offs[i] - offs.first) / speedMps).round());
}

/// Runs of the variant's timetable direction that did not start (the server saw no bus leave for
/// them: seen false) and would reach stop [i] of [variantId] from [pastS] ago to [horizonS] ahead of
/// [nowWallS] (seconds since Athens midnight): their departure ("HH:MM") and the seconds until they
/// would have been at the stop (negative: already). Same run time as [plannedEtas].
List<({String t, int etaS})> missedRuns(Map<String, dynamic> schedule, LineStatic st, String variantId, int i, int nowWallS,
    {double speedMps = 4.2, int pastS = 900, int horizonS = 1800}) {
  final v = st.variants[variantId];
  final dir = v == null ? null : directionFor(schedule, v);
  final offs = st.offsetsFor(variantId);
  if (dir == null || i < 0 || i >= offs.length) return const [];
  final run = (offs[i] - offs.first) / speedMps;
  final out = <({String t, int etaS})>[];
  for (final x in dir['departures'] as List? ?? const []) {
    final m = x as Map;
    if (m['seen'] != false) continue;
    final t = '${m['t'] ?? ''}';
    final p = t.split(':');
    final h = p.length >= 2 ? int.tryParse(p[0]) : null, mm = p.length >= 2 ? int.tryParse(p[1]) : null;
    if (h == null || mm == null) continue;
    final eta = (h * 3600 + mm * 60 + run - nowWallS).round();
    if (eta >= -pastS && eta <= horizonS) out.add((t: t, etaS: eta));
  }
  return out;
}

/// Seconds until runs that have not started yet reach stop [i] of [variantId]: each departure from the
/// start ("HH:MM", GTFS style, "24:15" after midnight) not yet gone at [nowWallS] (seconds since Athens
/// midnight), plus the distance to the stop at [speedMps]. Within [horizonS]; with [afterS], only runs
/// more than 2′ after it (the last live bus of the direction covers its own run).
List<int> plannedEtas(List<String> deps, LineStatic st, String variantId, int i, int nowWallS,
    {int? afterS, double speedMps = 4.2, int horizonS = 3600}) {
  final offs = st.offsetsFor(variantId);
  if (i < 0 || i >= offs.length) return const [];
  final run = (offs[i] - offs.first) / speedMps;
  final out = <int>[];
  for (final t in deps) {
    final p = t.split(':');
    final h = p.length >= 2 ? int.tryParse(p[0]) : null, m = p.length >= 2 ? int.tryParse(p[1]) : null;
    if (h == null || m == null) continue;
    final dep = h * 3600 + m * 60;
    if (dep < nowWallS - 60) continue; // gone: a live bus or a run that did not start
    final eta = (dep + run - nowWallS).round();
    if (eta > horizonS || (afterS != null && eta <= afterS + 120)) continue;
    out.add(eta);
  }
  return out..sort();
}
