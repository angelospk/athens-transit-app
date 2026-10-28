// Natural motion for every moving dot, ported from the web's motion.ts. The shown point chases a
// target along a polyline: faster when late, slower when early, never backwards. A target far behind
// (or very far ahead) gets a "correction" instead: a glide from the shown point to it, since only a
// jump can get there. Geometry is (lat, lon) `Pt`; times are seconds. No Timers: the caller passes
// the time in, so every step is pure and deterministic.

import 'dart:math';

import 'geo.dart' show Pt, distM;

const tauS = 10.0; // a gap closes with this time constant...
const catchMax = 6.0; // ...at most this much faster than the target (m/s): no burst after new data
const farM = 600.0; // farther ahead: a correction, not a race
const glideBaseS = 1.2; // the shortest glide: back, and the shortest ahead
const glideMaxS = 2.4; // the longest ahead
const _glideMPerS = 1200.0; // ahead: glideBaseS plus a second per this many metres
const snapS = 3.0; // longer between steps (app in the background): just snap
const nearM = 30.0; // a shown point this close to new geometry continues on it
const joinM = 40.0; // otherwise, at most this far it glides there
const behindDeg = 110.0; // a fix this far off the travel bearing is behind
const noiseM = 25.0; // shorter backward moves are GPS noise
const offS = 1.2; // a sideways offset fades out over at least this...
const offV = 5.0; // ...and at most this fast (m/s at the steepest point)

// Driving with stops (docs/research/realistic-motion.md on the web): the bus cruises, brakes into
// every stop, waits there and pulls away again. Its mean speed, stops included, is pace times the
// measured one (a little slow: a late catch-up looks better than a reverse).
const pace = 0.85;
const dwellS = 15.0; // wait at each stop
const horizonS = 180.0; // after this long without a new fix, stand
const noSpeed = 1.5; // m/s for a vehicle on its route without a measured speed
const minCruise = 3.0; // m/s; slower traffic waits longer at stops instead
const stepM = 200.0; // metres per path_speeds step (contract rev 6)
const _acc = 1.0; // m/s², braking and pulling away
const _stopGapM = 400.0; // stop spacing when fewer than two gaps are known
const _maxCruise = 15.0; // m/s

const _rad = pi / 180;
const _mPerDeg = 111320.0; // metres per degree on the local flat projection below

typedef _Phase = ({double t, double s, double v, double a});

/// Metres from the fix dt seconds after it, at measured mean speed v (m/s). stops: metres ahead,
/// ascending; the vehicle stands for good at `end`.
double Function(double) drive(double v, List<double> stops, double end,
    {double horizon = horizonS, double cruiseFloor = minCruise}) {
  final mean = pace * v;
  if (!(mean > 0) || !(end > 0)) return (_) => 0;
  final ahead = <double>[];
  for (final x in stops) {
    if (x >= 1 && x < end && x - (ahead.isEmpty ? 0 : ahead.last) >= 1) ahead.add(x); // listed twice: once
  }
  final legs = [...ahead, end];
  // Cruise so that, over a typical gap, cruising plus one wait gives the mean speed. No stops
  // known: no waits either, so cruise at the mean.
  final gaps = [for (var i = 0; i < min(4, ahead.length); i++) ahead[i] - (i > 0 ? ahead[i - 1] : 0)];
  final l = gaps.length >= 2 ? gaps.reduce((a, b) => a + b) / gaps.length : _stopGapM;
  final run = l / mean - dwellS;
  var vc = ahead.isEmpty ? min(mean, _maxCruise) : (run > l / _maxCruise ? l / run : _maxCruise);
  var dwell = dwellS;
  if (ahead.isNotEmpty && vc < cruiseFloor) {
    vc = cruiseFloor;
    dwell = max(dwellS, l / mean - l / vc);
  }
  final ph = <_Phase>[];
  var t = 0.0, s = 0.0, u = vc;
  void go(double dur, double a) {
    if (dur <= 0) return;
    ph.add((t: t, s: s, v: u, a: a));
    s += u * dur + a * dur * dur / 2;
    u += a * dur;
    t += dur;
  }

  for (final x in legs) {
    if (t >= horizon) break;
    final d = x - s;
    if (d < 1) continue; // the end right at the last stop
    if (u * u / (2 * _acc) >= d) {
      go(2 * d / u, -(u * u) / (2 * d)); // too close: brake harder
    } else {
      final top = min(vc, sqrt(_acc * d + u * u / 2));
      final up = (top * top - u * u) / (2 * _acc), down = top * top / (2 * _acc);
      go((top - u) / _acc, _acc);
      go((d - up - down) / top, 0);
      go(top / _acc, -_acc);
    }
    s = x;
    u = 0;
    ph.add((t: t, s: s, v: 0, a: 0));
    t += dwell;
  }
  if (ph.isEmpty) return (_) => 0; // less than a metre to go
  return (dt) {
    final k = min(max(dt, 0.0), horizon);
    var p = ph.first;
    for (final q in ph) {
      if (q.t <= k) {
        p = q;
      } else {
        break;
      }
    }
    final r = k - p.t;
    return min(end, max(p.s, p.s + p.v * r + p.a * r * r / 2));
  };
}

/// Metres from the fix dt seconds after it, at the backend's typical speeds per stepM: step i covers
/// metres [i*stepM, (i+1)*stepM) at steps[i]; a null step, and everything after the last step, at
/// `fallback`. Stands for good at a speed <= 0, never past `end`.
double Function(double) walk(List<double?> steps, double fallback, double end,
    {double horizon = horizonS}) {
  if (!(end > 0)) return (_) => 0;
  final ph = <_Phase>[];
  var t = 0.0, s = 0.0;
  void add(double v, double d) {
    ph.add((t: t, s: s, v: v, a: 0));
    t += d / v;
    s += d;
  }

  for (var i = 0; s < end; i++) {
    final v = (i < steps.length ? steps[i] : null) ?? fallback;
    if (!(v > 0)) break;
    add(v, min(stepM, end - s));
  }
  if (ph.isEmpty) return (_) => 0; // standing from the start
  final limit = s;
  return (dt) {
    final k = min(max(dt, 0.0), horizon);
    var p = ph.first;
    for (final q in ph) {
      if (q.t <= k) {
        p = q;
      } else {
        break;
      }
    }
    return min(limit, p.s + p.v * (k - p.t));
  };
}

/// Where a dot should be drawn along a polyline, and how that target moves in time.
class Plan {
  final List<Pt> geom;
  final List<double> cum; // metres from geom[0] to each point
  final double Function(double tSec) target; // metres along geom where the dot should be
  final ({List<Pt> geom, double ds})? base; // a handoff onto geom: s here is s + ds there
  const Plan({required this.geom, required this.cum, required this.target, this.base});
}

/// A plan handed to a dot, with where on it the dot starts and whether it needs a correction.
class Handoff {
  final Plan plan;
  final double s0;
  final Pt? off; // sideways offset (dLat, dLon), faded out after a near handoff
  final bool fix;
  final bool back;
  const Handoff({required this.plan, required this.s0, this.off, this.fix = false, this.back = false});
}

/// How far ahead of the target a dot may be and still just wait for it, in metres.
double holdM(double v) => min(80.0, max(25.0, 8 * v));

/// One step of the chase: the new shown s, or null ("fix") when only a correction can get there.
double? chase(double s, double target, double v, double dt) {
  final gap = target - s;
  if (gap > farM) return null;
  if (gap >= 0) return s + min(gap, (v + min(gap / tauS, catchMax)) * dt);
  final ahead = -gap, hold = holdM(v);
  if (ahead > hold) return null;
  return s + v * max(0.0, 1 - ahead / hold) * dt; // let the target catch up
}

/// Metres from the first point of the polyline to each point.
List<double> cumulative(List<Pt> geom) {
  final out = <double>[0];
  for (var i = 1; i < geom.length; i++) {
    out.add(out[i - 1] + distM(geom[i - 1], geom[i]));
  }
  return out;
}

/// The point s metres along the polyline (clamped to its ends).
Pt pointAtCum(List<Pt> geom, List<double> cum, double s) {
  for (var i = 1; i < geom.length; i++) {
    final len = cum[i] - cum[i - 1];
    if (len > 0 && cum[i] >= s) {
      final k = max(0.0, s - cum[i - 1]) / len, a = geom[i - 1], b = geom[i];
      return (a.$1 + (b.$1 - a.$1) * k, a.$2 + (b.$2 - a.$2) * k);
    }
  }
  return geom.last;
}

/// Which way a point moves along the polyline, in degrees clockwise from north, or null.
double? headingAt(List<Pt> geom, List<double> cum, double s) {
  for (var i = 1; i < geom.length; i++) {
    if (cum[i] > cum[i - 1] && (cum[i] >= s || i == geom.length - 1)) {
      return _bearingDeg(geom[i - 1], geom[i]);
    }
  }
  return null;
}

// Degrees clockwise from north from a to b.
double _bearingDeg(Pt a, Pt b) {
  final dx = (b.$2 - a.$2) * cos(a.$1 * _rad), dy = b.$1 - a.$1;
  return (atan2(dx, dy) * 180 / pi + 360) % 360;
}

// The smaller angle between two bearings, 0..180.
double _angle(double a, double b) => ((a - b + 540) % 360 - 180).abs();

// Nearest point of the polyline to p: s along it and metres off. With `hint`, of the legs nearly as
// close as the nearest (loops, out-and-back streets), the one whose s is closest to the hint.
({double s, double off}) projectCum(List<Pt> geom, List<double> cum, Pt p, {double? hint}) {
  final kx = cos(p.$1 * _rad), hits = <({double s, double off})>[];
  for (var i = 1; i < geom.length; i++) {
    final a = geom[i - 1], b = geom[i];
    final ax = (a.$2 - p.$2) * kx, ay = a.$1 - p.$1;
    final dx = (b.$2 - a.$2) * kx, dy = b.$1 - a.$1;
    final len = dx * dx + dy * dy;
    final t = len > 0 ? max(0.0, min(1.0, -(ax * dx + ay * dy) / len)) : 0.0;
    final ex = ax + t * dx, ey = ay + t * dy;
    hits.add((s: cum[i - 1] + t * (cum[i] - cum[i - 1]), off: sqrt(ex * ex + ey * ey) * _mPerDeg));
  }
  if (hits.isEmpty) return (s: 0.0, off: geom.isEmpty ? double.infinity : distM(p, geom.first));
  final minOff = hits.map((h) => h.off).reduce(min);
  if (hint == null) return hits.firstWhere((h) => h.off == minOff);
  final near = hits.where((h) => h.off <= minOff + 20).toList();
  return near.reduce((best, h) => (h.s - hint).abs() < (best.s - hint).abs() ? h : best);
}

/// How long a correction glide lasts: back is quick; ahead, longer for a longer jump.
double glideS(double m, bool back) =>
    back ? glideBaseS : min(glideMaxS, glideBaseS + max(0.0, m) / _glideMPerS);

// 0..1, starts and ends gently.
double _smooth(double k) => k * k * (3 - 2 * k);

// 0..1, starts and ends gently, steeper in the middle.
double _easeInOut(double k) {
  if (k < 0.5) return 4 * k * k * k;
  final m = -2 * k + 2;
  return 1 - m * m * m / 2;
}

// The shown point joined to the polyline at s = at: [shown, point(at), ...rest]; target shifted.
Handoff _joinAt(Pt shown, Plan p, double at) {
  final start = pointAtCum(p.geom, p.cum, at), d = distM(shown, start);
  final rest = <Pt>[for (var i = 0; i < p.geom.length; i++) if (p.cum[i] > at) p.geom[i]];
  final geom = [shown, start, ...rest];
  return Handoff(
    plan: Plan(geom: geom, cum: cumulative(geom), target: (t) => d + max(0.0, p.target(t) - at), base: (geom: p.geom, ds: at - d)),
    s0: 0,
  );
}

/// Hand a shown dot over to new geometry without a jump.
Handoff planOnto(Pt shown, Plan p, double nowSec) {
  final now = p.target(nowSec), pr = projectCum(p.geom, p.cum, shown, hint: now);
  if (pr.off <= nearM) {
    final q = pointAtCum(p.geom, p.cum, pr.s);
    return Handoff(plan: p, s0: pr.s, off: (shown.$1 - q.$1, shown.$2 - q.$2));
  }
  // Behind the start, roughly in the travel direction: drive up to it.
  if (pr.s < 1 && p.geom.length > 1) {
    final d = distM(shown, p.geom.first), h = headingAt(p.geom, p.cum, 0);
    if (d <= farM && h != null && _angle(_bearingDeg(shown, p.geom.first), h) < 60) {
      return _joinAt(shown, p, 0);
    }
  }
  final j = _joinAt(shown, p, now);
  return distM(shown, pointAtCum(p.geom, p.cum, now)) <= joinM ? j : Handoff(plan: j.plan, s0: 0, fix: true);
}

/// A backend `path` (already (lat, lon)) driven at `speed` from position_at `at`, waiting at `stops`
/// (metres along it). With `steps` (path_speeds) it walks those typical speeds instead: no stop waits.
Handoff pathPlan(Pt shown, List<Pt> path, double speed, double at, double nowSec,
    {List<double> stops = const [], List<double?>? steps}) {
  final cum = cumulative(path), end = cum.last;
  final f = steps != null && steps.isNotEmpty ? walk(steps, speed, end) : drive(speed, stops, end);
  return planOnto(shown, Plan(geom: path, cum: cum, target: (t) => f(t - at)), nowSec);
}

/// No geometry: glide straight to a fixed point. With a bearing, a point well behind is a correction.
Handoff linePlan(Pt shown, Pt to, double? bearing) {
  final d = distM(shown, to);
  final behind = bearing != null && d > noiseM && _angle(_bearingDeg(shown, to), bearing) > behindDeg;
  return Handoff(
    plan: Plan(geom: [shown, to], cum: [0, d], target: (_) => d),
    s0: 0,
    fix: behind || d > farM,
    back: behind,
  );
}

// One vehicle's place in the chase: its plan, where it is on it, and any correction glide.
class _Track {
  Plan? plan;
  double s = 0; // metres along plan
  Pt pos; // the shown point
  double last;
  int positionAt = 0;
  List<Pt>? path; // the path the plan was built from
  ({double t0, Pt from, double dur, bool back})? glide;
  Pt? off; // sideways offset still fading out (dLat, dLon)
  double offAt = 0, offDur = offS;

  _Track(this.pos, this.last);
}

// Per-vehicle tracker: the web does this in its map code. Call update() when a vehicle's data
// arrives (cheap with the same data), step() every frame, retain() to drop vehicles that left.
class Motion {
  final Map<String, _Track> _tracks = {};

  // The point shown for this vehicle now, or null if it is not tracked.
  Pt? shown(String id) => _tracks[id]?.pos;

  // A vehicle's newest data. A new plan only when its position_at or its path really changed, so
  // calling it every tick with the same data costs a comparison.
  void update(
    String id, {
    required List<Pt>? path,
    required double? speed,
    required int positionAt,
    required List<double?>? pathSpeeds,
    required Pt fix,
    double? bearing,
    required double nowS,
    List<double>? pathStops,
  }) {
    final t = _tracks.putIfAbsent(id, () => _Track(fix, double.negativeInfinity));
    if (t.last > double.negativeInfinity && t.positionAt == positionAt && _samePath(t.path, path)) return;
    final first = t.last == double.negativeInfinity;
    t.positionAt = positionAt;
    t.path = path;
    final h = path != null && path.length > 1
        ? pathPlan(t.pos, path, speed ?? noSpeed, positionAt.toDouble(), nowS, stops: pathStops ?? const [], steps: pathSpeeds)
        : linePlan(t.pos, fix, bearing);
    t.plan = h.plan;
    if (first) {
      // First sight of a vehicle: show it where it is, without an animation.
      t.last = nowS;
      t.s = h.plan.target(nowS);
      t.pos = pointAtCum(h.plan.geom, h.plan.cum, t.s);
      t.glide = null;
      t.off = null;
      return;
    }
    t.s = h.s0;
    if (h.fix) {
      _startGlide(t, nowS, h.back);
    } else {
      t.glide = null;
      final off = h.off;
      t.off = off != null && (off.$1 != 0 || off.$2 != 0) ? off : null;
      t.offAt = nowS;
      // smoothstep's steepest slope is 1.5 / duration
      if (t.off case final o?) t.offDur = max(offS, 1.5 * distM(t.pos, (t.pos.$1 - o.$1, t.pos.$2 - o.$2)) / offV);
    }
  }

  // Move this vehicle to nowS and return where it is shown.
  Pt step(String id, double nowS) {
    final t = _tracks[id];
    if (t == null) throw StateError('step before update: $id');
    final dt = nowS - t.last;
    t.last = nowS;
    final p = t.plan;
    if (p == null) return t.pos;
    final target = p.target(nowS);
    if (dt > snapS || dt < 0) {
      // The app was not drawing for a while: jump, effect included.
      t.s = target;
      t.glide = null;
      t.off = null;
      return t.pos = pointAtCum(p.geom, p.cum, t.s);
    }
    if (t.glide case final g?) {
      final k = (nowS - g.t0) / g.dur;
      if (k < 1) return t.pos = _lerp(g.from, pointAtCum(p.geom, p.cum, target), _easeInOut(max(0.0, k)));
      t.glide = null;
      t.s = target;
    }
    final v = max(0.0, p.target(nowS + 1) - target);
    final r = chase(t.s, target, v, dt);
    if (r == null) {
      _startGlide(t, nowS, target < t.s); // only a correction gets there
    } else {
      t.s = r;
    }
    return t.pos = _place(t, nowS);
  }

  // Drop every vehicle not in `ids` (it left the map, the feed or the filter).
  void retain(Set<String> ids) => _tracks.removeWhere((id, _) => !ids.contains(id));

  // Start a correction glide from the shown point to the target.
  void _startGlide(_Track t, double nowS, bool back) {
    final p = t.plan!;
    t.glide = (t0: nowS, from: t.pos, dur: glideS(distM(t.pos, pointAtCum(p.geom, p.cum, p.target(nowS))), back), back: back);
    t.off = null;
  }

  // The shown point on the plan, with whatever sideways offset is still fading out.
  Pt _place(_Track t, double nowS) {
    final p = t.plan!;
    var pos = pointAtCum(p.geom, p.cum, t.s);
    if (t.off case final o?) {
      final k = (nowS - t.offAt) / t.offDur;
      if (k >= 1) {
        t.off = null;
      } else {
        final w = 1 - _smooth(max(0.0, k));
        pos = (pos.$1 + o.$1 * w, pos.$2 + o.$2 * w);
      }
    }
    return pos;
  }
}

// The same path: the same list, or one rebuilt from the same data (same ends).
bool _samePath(List<Pt>? a, List<Pt>? b) {
  if (identical(a, b)) return true;
  if (a == null || b == null || a.length != b.length || a.isEmpty) return false;
  return a.first == b.first && a.last == b.last;
}

Pt _lerp(Pt a, Pt b, double k) => (a.$1 + (b.$1 - a.$1) * k, a.$2 + (b.$2 - a.$2) * k);
