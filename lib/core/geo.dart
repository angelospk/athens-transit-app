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

/// s of each stop, in order: among the legs at or after the previous stop, the closest
/// one, then the earliest. Monotone non-decreasing.
List<double> stopOffsets(List<Pt> shape, List<Pt> stops) {
  var prev = 0.0;
  return [
    for (final p in stops)
      () {
        Proj? best;
        for (final c in projectCandidates(shape, p)) {
          if (c.s < prev - _backM) continue;
          if (best == null || c.offM < best.offM - 0.5) best = c;
        }
        final s = max(prev, best?.s ?? prev);
        prev = s;
        return s;
      }()
  ];
}
