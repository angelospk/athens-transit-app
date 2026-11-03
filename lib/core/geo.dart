import 'dart:math';

/// (lat, lon) in degrees.
typedef Pt = (double, double);

const _earthR = 6371008.8;
const _rad = pi / 180;
const _mPerDeg = _earthR * _rad;

/// Great-circle distance in metres (haversine).
double distM(Pt a, Pt b) {
  final dLat = (b.$1 - a.$1) * _rad;
  final dLon = (b.$2 - a.$2) * _rad;
  final h = pow(sin(dLat / 2), 2) + cos(a.$1 * _rad) * cos(b.$1 * _rad) * pow(sin(dLon / 2), 2);
  return 2 * _earthR * asin(min(1.0, sqrt(h)));
}

double shapeLength(List<Pt> shape) {
  var d = 0.0;
  for (var i = 1; i < shape.length; i++) {
    d += distM(shape[i - 1], shape[i]);
  }
  return d;
}

/// Point `s` metres along the shape (clamped to its ends).
Pt pointAt(List<Pt> shape, double s) {
  if (s <= 0 || shape.length < 2) return shape.first;
  var walked = 0.0;
  for (var i = 1; i < shape.length; i++) {
    final a = shape[i - 1], b = shape[i];
    final len = distM(a, b);
    if (walked + len >= s && len > 0) {
      final k = (s - walked) / len;
      return (a.$1 + (b.$1 - a.$1) * k, a.$2 + (b.$2 - a.$2) * k);
    }
    walked += len;
  }
  return shape.last;
}

typedef Proj = ({double s, double offM});

// Nearest point of segment ab to p on a local flat projection: (fraction along ab, metres off).
(double, double) _nearestOnSegment(Pt p, Pt a, Pt b) {
  final kx = cos(p.$1 * _rad);
  final ax = (a.$2 - p.$2) * kx, ay = a.$1 - p.$1;
  final dx = (b.$2 - a.$2) * kx, dy = b.$1 - a.$1;
  final len = dx * dx + dy * dy;
  final t = len > 0 ? max(0.0, min(1.0, -(ax * dx + ay * dy) / len)) : 0.0;
  return (t, sqrt(pow(ax + t * dx, 2) + pow(ay + t * dy, 2)) * _mPerDeg);
}

const _tieM = 20.0; // other legs this close to the nearest are candidates too
const _mergeM = 50.0; // candidates closer than this along the shape are one
const _backM = 30.0; // GPS noise backwards along the route
const _leftOutCost = 150.0 + _tieM + 1; // a stop left out costs more than the worst leg's offset

/// Every leg of the shape that passes within 20 m of the nearest one (and within
/// [maxOffM]), by s, one per leg of a loop or out-and-back.
List<Proj> projectCandidates(List<Pt> shape, Pt p, {double maxOffM = 150}) {
  if (shape.length < 2) return const [];
  final hits = <Proj>[];
  var walked = 0.0;
  for (var i = 1; i < shape.length; i++) {
    final len = distM(shape[i - 1], shape[i]);
    final (t, off) = _nearestOnSegment(p, shape[i - 1], shape[i]);
    hits.add((s: walked + t * len, offM: off));
    walked += len;
  }
  final minOff = hits.map((h) => h.offM).reduce(min);
  if (!(minOff <= maxOffM)) return const [];
  final near = hits.where((h) => h.offM <= minOff + _tieM).toList()..sort((x, y) => x.s.compareTo(y.s));
  final out = <Proj>[];
  for (final h in near) {
    if (out.isNotEmpty && h.s - out.last.s < _mergeM) {
      if (h.offM < out.last.offM) out[out.length - 1] = h;
    } else {
      out.add(h);
    }
  }
  return out;
}

/// Nearest projection of p onto the shape, or null when farther than [maxOffM].
Proj? project(List<Pt> shape, Pt p, {double maxOffM = 150}) {
  Proj? best;
  for (final c in projectCandidates(shape, p, maxOffM: maxOffM)) {
    if (best == null || c.offM < best.offM) best = c;
  }
  return best;
}

/// One way to place the stops so far: the last stop's [s], the furthest s reached, its [cost] and the
/// step it came from.
class _Step {
  final double s, max, cost;
  final int from;
  const _Step(this.s, this.max, this.cost, this.from);
}

/// s of each stop, chosen for the whole run: the placement of all the stops whose sum of offsets from
/// the shape is smallest, kept in order along the shape (a small step back is GPS noise). A stop may be
/// left out instead, at a cost above any leg's offset: the stop takes the place of the one before it,
/// so two stops in the wrong order cost one stop, not every stop after them. A loop starts and ends at
/// one stop, so its first stop sits at the start of the shape and not at its end: both are the same
/// place, and the end is often nearer.
List<double> stopOffsets(List<Pt> shape, List<Pt> stops) {
  final steps = <List<_Step>>[];
  for (final p in stops) {
    final before = steps.isEmpty ? const [_Step(0, 0, 0, -1)] : steps.last;
    final next = <_Step>[];
    for (final c in projectCandidates(shape, p)) {
      _Step? best;
      for (var k = 0; k < before.length; k++) {
        final b = before[k];
        if (c.s < b.max - _backM) continue;
        final cost = b.cost + c.offM;
        if (best == null || cost < best.cost - 0.5) best = _Step(c.s, max(b.max, c.s), cost, k);
      }
      if (best != null) next.add(best);
    }
    // After the legs: on equal cost, a stop in place wins over one left out.
    for (var k = 0; k < before.length; k++) {
      final b = before[k];
      next.add(_Step(b.s, b.max, b.cost + _leftOutCost, k));
    }
    steps.add(next);
  }
  if (steps.isEmpty) return const [];
  final last = steps.last;
  var k = 0;
  for (var i = 1; i < last.length; i++) {
    if (last[i].cost < last[k].cost - 0.5) k = i;
  }
  final out = List<double>.filled(steps.length, 0);
  for (var i = steps.length - 1; i >= 0; i--) {
    out[i] = steps[i][k].s;
    k = steps[i][k].from;
  }
  return out;
}
