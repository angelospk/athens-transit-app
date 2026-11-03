// A loop line starts and ends at the same place: its first stop must sit at the start of the shape,
// not at its end (QA: line 732, every stop at 17 km, so a stop 26 stops in looked 0 m from the start).
import 'dart:math';

import 'package:athens_transit/core/geo.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  loopFarFromStart();
  leastCostOrder();
  test('the first stop of a loop sits at the start, even when the end of the shape is nearer', () {
    const d = 0.009; // ~1 km north, ~790 m east
    // A square loop as line 732 draws it: the first stop is 29 m from the start of the shape, 5 m from its end.
    final shape = <Pt>[(38.0, 23.7), (38.0 + d, 23.7), (38.0 + d, 23.7 + d), (38.0, 23.7 + d), (38.0, 23.69966)];
    final stops = <Pt>[(38.0, 23.69961), (38.0 + d, 23.7 + d / 2), (38.0, 23.7 + d / 2)];
    final s = stopOffsets(shape, stops);
    expect(s[0], lessThan(50));
    expect(s[1], closeTo(1000 + 395, 30));
    expect(s[2], closeTo(1000 + 790 + 1000 + 395, 30));
  });

  test('a line whose shape starts before its first stop keeps the stop where it is', () {
    final shape = <Pt>[(38.0, 23.7), (38.009, 23.7)];
    expect(stopOffsets(shape, [(38.0009, 23.7), (38.005, 23.7)])[0], closeTo(100, 5));
  });
}

// A loop whose terminus stands more than 150 m from both ends of the shape (309Β, 171, 309, 311, 330):
// the shape passes it twice, going out and coming back; the way back passes 2 m nearer. Every stop
// sat at the shape's end and showed one time. As in the web (web#16): chosen for the whole run.
void loopFarFromStart() {
  test('a loop terminus far from the shape ends sits on the way out, and the stops after it follow', () {
    final shape = <Pt>[
      (37.97, 23.703), (37.97, 23.69), (37.98, 23.69), (37.98, 23.71), (37.97002, 23.71), (37.97002, 23.697),
    ];
    final stops = <Pt>[(37.971, 23.70), (37.975, 23.69), (37.98, 23.70), (37.975, 23.71)];
    final s = stopOffsets(shape, stops);
    expect(s[0], lessThan(400));
    expect(s[0], lessThan(s[1]));
    expect(s[1], lessThan(s[2]));
    expect(s[2], lessThan(s[3]));
  });

  test('of two stops in the wrong order on a one-way shape, the later one is left out, not all after it', () {
    final east = <Pt>[(37.97, 23.70), (37.97, 23.71), (37.97, 23.72)];
    const m = 877.4; // 0.01° of longitude here
    final s = stopOffsets(east, [(37.97, 23.709), (37.97, 23.705), (37.97, 23.711)]);
    expect(s[0], 0);
    expect(s[1], closeTo(0.5 * m, 10));
    expect(s[2], closeTo(1.1 * m, 10));
  });
}

// Local metres (x east, y north) near 37.97°N, for hand-built shapes and stops.
final _kx = 111320 * cos(37.97 * pi / 180);
Pt _xy(double x, double y) => (37.97 + y / 111320, 23.70 + x / _kx);
const _leftOut = 171.0;

// Least cost over every order: each stop takes a leg (no more than 30 m behind any before it) or is left out.
double _bestCost(List<Pt> shape, List<Pt> stops) {
  final cands = [for (final p in stops) projectCandidates(shape, p)];
  var best = double.infinity;
  void go(int i, double mx, double cost) {
    if (i == stops.length) {
      best = min(best, cost);
      return;
    }
    for (final c in cands[i]) {
      if (c.s >= mx - 30) go(i + 1, max(mx, c.s), cost + c.offM);
    }
    go(i + 1, mx, cost + _leftOut);
  }

  go(0, 0, 0);
  return best;
}

double _costOf(List<Pt> shape, List<Pt> stops, List<double> s) {
  var t = 0.0;
  for (var i = 0; i < s.length; i++) {
    final c = projectCandidates(shape, stops[i]).where((c) => (c.s - s[i]).abs() < 0.01);
    t += c.isEmpty ? _leftOut : c.first.offM;
  }
  return t;
}

// One best path per leg is not enough: a costlier path that reached a lower max rules out fewer later
// legs (web#20).
void leastCostOrder() {
  test('on an out-and-back, a costlier path to a leg is kept when it rules out fewer later legs', () {
    // 200 m out, 1 m apart, 200 m back. One best path per leg gives cost 21; 20 exists.
    final shape = [_xy(0, 0), _xy(200, 0), _xy(200, 1), _xy(0, 1)];
    final stops = [_xy(138, 10), _xy(120, 3), _xy(136, 3), _xy(160, 5), _xy(148, 0)];
    expect(_bestCost(shape, stops), closeTo(20, 0.05));
    expect(_costOf(shape, stops, stopOffsets(shape, stops)), closeTo(20, 0.05));
  });

  test('the leg nearer by 0.1 m is taken, also when it lies far along the route', () {
    // 2 km out, 1 m apart, 2 km back; the stop is 0.55 m from the way out, 0.45 m from the way back.
    final shape = [_xy(0, 0), _xy(2000, 0), _xy(2000, 1), _xy(0, 1)];
    expect(stopOffsets(shape, [_xy(200, 0.55)])[0], closeTo(2000 + 1 + 1800, 5));
  });

  test('on a straight route, the one stop that rules out two is left out', () {
    // Stops at 100, 80, 60, 65, 70 m: leaving 100 out costs 171; one best path per leg left two out (342).
    final shape = [_xy(0, 0), _xy(500, 0)];
    final stops = [for (final x in [100.0, 80.0, 60.0, 65.0, 70.0]) _xy(x, 0)];
    final s = stopOffsets(shape, stops);
    expect(_costOf(shape, stops, s), closeTo(_leftOut, 0.5));
    expect(s.map((x) => x.round()).toList(), [0, 80, 60, 65, 70]);
  });
}
