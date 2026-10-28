// The web's motion tests (tests/motion.test.ts), ported: the same cases in (lat, lon), plus the
// app-side Motion tracker with synthetic paths.

import 'package:athens_transit/core/geo.dart';
import 'package:athens_transit/core/motion.dart';
import 'package:flutter_test/flutter_test.dart';

// 0.01° lon at 37.97° ≈ 877 m. Geometry here is (lat, lon).
final east = <Pt>[(37.97, 23.70), (37.97, 23.71), (37.97, 23.72)];
final m = distM(east[0], east[1]);
Pt atM(double metres) => (37.97, 23.70 + (metres / m) * 0.01);

// East m metres, then north: a bend at s = m.
final bent = <Pt>[(37.97, 23.70), (37.97, 23.71), (37.98, 23.71)];
final n = distM(bent[1], bent[2]);
Pt onBent(double metres) => metres <= m ? atM(metres) : (37.97 + ((metres - m) / n) * 0.01, 23.71);

Plan planOf(double Function(double) target, [List<Pt>? geom]) {
  final g = geom ?? east;
  return Plan(geom: g, cum: cumulative(g), target: target);
}

double sAlong(List<Pt> geom, Pt p) => projectCum(geom, cumulative(geom), p).s;

void main() {
  group('chase', () {
    test('moves at target speed when on target, faster when behind, never overshoots', () {
      expect(chase(96, 100, 8, 0.5), 100); // the target moved 4 m: reach it
      final late = chase(0, 100, 8, 0.5)!;
      expect(late, greaterThan(0.5 * 8)); // faster than v
      expect(late, lessThanOrEqualTo(0.5 * (8 + catchMax) + 1e-9)); // capped catch-up
      expect(catchMax, lessThanOrEqualTo(6)); // no burst after new data
      expect(chase(99, 100, 0, 5), lessThanOrEqualTo(100)); // no overshoot
      expect(chase(99, 100, 0, 5), greaterThan(99));
    });

    test('slows down instead of reversing when a little ahead', () {
      final ahead = chase(110, 100, 8, 0.5)!;
      expect(ahead, greaterThanOrEqualTo(110));
      expect(ahead - 110, lessThan(4));
      expect(chase(120, 100, 0, 1), 120); // standing target: wait
    });

    test('asks for a correction when far behind the target or far ahead of it', () {
      expect(chase(100 + holdM(8) + 1, 100, 8, 0.1), isNull);
      expect(chase(0, 700, 8, 0.1), isNull);
      expect(holdM(0), 25);
      expect(holdM(100), 80);
    });
  });

  group('geometry', () {
    test('walks and projects along lat/lon polylines', () {
      final cum = cumulative(east);
      expect(distM(pointAtCum(east, cum, 300), atM(300)), lessThan(0.5));
      expect(pointAtCum(east, cum, 1e6), east[2]);
      final p = projectCum(east, cum, (37.9701, 23.705));
      expect(p.s, closeTo(m / 2, 5));
      expect(p.off, closeTo(11, 1));
      expect(projectCum(east, cum, (37.97, 23.69)).s, 0);
    });

    test('gives the way a point travels along the polyline', () {
      final cum = cumulative(bent);
      expect(headingAt(bent, cum, 200), closeTo(90, 1));
      expect(headingAt(bent, cum, m + 300), closeTo(0, 1));
      expect(headingAt(<Pt>[(37.97, 23.70)], <double>[0], 0), isNull);
    });
  });

  group('drive', () {
    final stops = [for (var i = 1; i <= 20; i++) 300.0 * i];

    test('keeps pace times the measured mean speed, stops included', () {
      final f = drive(5, stops, 1e6, horizon: 600);
      expect(f(300) / 300, greaterThan(0.9 * pace * 5));
      expect(f(300) / 300, lessThan(1.1 * pace * 5));
    });

    test('without known stops, cruises at the mean speed (no waits to make up for)', () {
      final f = drive(10, <double>[], 1e6);
      expect(f(100) / 100, closeTo(pace * 10, 1e-6));
    });

    test('counts a stop listed twice once', () {
      final twice = [for (final x in stops) ...[x, x]];
      expect(drive(5, twice, 1e6)(200), closeTo(drive(5, stops, 1e6)(200), 1e-6));
    });

    test('brakes into each stop and waits there dwellS', () {
      final f = drive(5, stops, 1e6);
      var t = 0.0;
      while (f(t) < 300 - 1e-6) {
        t += 0.1;
      }
      expect(f(t - 1) - f(t - 2), lessThan(2)); // slow just before the stop
      expect(f(t + dwellS - 0.5), closeTo(300, 1e-6)); // standing
      expect(f(t + dwellS + 3), greaterThan(300)); // and off again
    });

    test('in slow traffic drives at minCruise and waits longer at stops, same mean', () {
      final f = drive(1.5, stops, 1e6, horizon: 1200);
      expect(f(1200) / 1200, greaterThan(0.9 * pace * 1.5));
      expect(f(1200) / 1200, lessThan(1.1 * pace * 1.5));
      var t = 0.0;
      while (f(t) < 300 - 1e-6) {
        t += 0.1;
      }
      expect(f(t - 5) - f(t - 6), greaterThan(minCruise - 0.5)); // cruising, not crawling
      expect(f(t + 60), closeTo(300, 1e-6)); // a long wait
    });

    test('never goes backwards, past the end or past the horizon', () {
      final f = drive(8, stops, 1000);
      var prev = 0.0;
      for (var t = 0.0; t <= 400; t += 0.5) {
        expect(f(t), greaterThanOrEqualTo(prev - 1e-9));
        prev = f(t);
      }
      expect(prev, lessThanOrEqualTo(1000));
      final g = drive(5, <double>[], 1e6);
      expect(g(horizonS + 60), g(horizonS));
    });

    test('brakes harder when the first stop is too close to brake gently', () {
      final f = drive(15, [10, 400], 1e6);
      var t = 0.0;
      while (f(t) < 10 - 1e-6) {
        t += 0.05;
      }
      expect(t, lessThan(5));
      expect(f(t + dwellS - 0.5), closeTo(10, 1e-6));
    });

    test('stands without a speed, before the fix and at the end', () {
      expect(drive(0, stops, 1e6)(60), 0);
      expect(drive(5, stops, 1e6)(-5), 0);
      expect(drive(5, stops, 0)(60), 0);
      expect(drive(5, <double>[], 0.5)(60), 0); // shorter than a metre: no phases
      expect(drive(5, [0.2, 0.4], 0.6)(60), 0);
      expect(drive(5, stops, 1e6, horizon: 0)(60), 0); // no horizon: no motion
      expect(drive(5, stops, 1e6, horizon: -10)(60), 0);
    });
  });

  group('walk (path_speeds)', () {
    test('moves at each 200 m step speed, then at the fallback', () {
      expect(stepM, 200);
      final f = walk([4, 2], 1, 1000);
      expect(f(10), closeTo(40, 1e-6));
      expect(f(50), closeTo(200, 1e-6));
      expect(f(60), closeTo(220, 1e-6));
      expect(f(150), closeTo(400, 1e-6));
      expect(f(160), closeTo(410, 1e-6)); // past the steps: fallback
    });

    test('takes a null step at the fallback; a zero fallback stands there', () {
      final f = walk([null, 5], 2, 1000);
      expect(f(100), closeTo(200, 1e-6));
      expect(f(110), closeTo(250, 1e-6));
      expect(walk([null], 0, 1000)(50), 0);
      expect(walk([3, null], 0, 1000)(500), closeTo(200, 1e-6));
    });

    test('stops at the end and after the horizon; nothing before the fix', () {
      expect(walk([10], 10, 150)(100), closeTo(150, 1e-6));
      expect(walk([1], 1, 1e4)(horizonS + 100), closeTo(horizonS, 1e-6));
      expect(walk([4], 4, 1000)(-5), 0);
    });
  });

  group('plans from new data', () {
    test('continues along a new path from the projected shown point', () {
      final r = pathPlan(atM(300), east, 8, 1000, 1000);
      expect(r.fix, isFalse);
      expect(r.s0, closeTo(300, 1));
      // the path starts at the fix
      expect(r.plan.target(1010), closeTo(drive(8, <double>[], cumulative(east).last)(10), 1e-6));
    });

    test('drives into the stops of the path and stops at its end', () {
      final end = cumulative(east).last;
      final r = pathPlan(atM(0), east, 15, 1000, 1000, stops: [400]);
      expect(r.plan.target(1600), closeTo(end, 1e-6));
      expect(r.plan.target(1040), closeTo(drive(15, [400], end)(40), 1e-6));
    });

    test('prepends the shown point when it is behind the new path start', () {
      final r = pathPlan((37.97, 23.695), east, 8, 1000, 1000);
      expect(r.fix, isFalse);
      expect(r.s0, 0);
      expect(r.plan.target(1000), closeTo(0.005 / 0.01 * m, 5));
    });

    test('falls back to a straight glide when close, else a correction', () {
      expect(pathPlan((37.9702, 23.705), east, 8, 1000, 1000).fix, isFalse); // 22 m off: projected
      final near = linePlan((37.9703, 23.7), (37.97, 23.7), null);
      expect(near.fix, isFalse);
      expect(near.plan.target(0), closeTo(33, 1));
    });

    test('treats a fix well behind the bearing as a correction', () {
      expect(linePlan(atM(100), atM(0), 90).fix, isTrue); // heading east, fix 100 m west
      expect(linePlan(atM(0), atM(100), 90).fix, isFalse); // ahead: glide
      expect(linePlan(atM(10), atM(0), 90).fix, isFalse); // GPS noise: glide
    });

    test('is what pathPlan drives when the vehicle has path_speeds (no stop waits)', () {
      final end = cumulative(east).last;
      final r = pathPlan(atM(0), east, 15, 1000, 1000, stops: [400], steps: [6, 3]);
      expect(r.plan.target(1040), closeTo(walk([6, 3], 15, end)(40), 1e-6));
      expect(pathPlan(atM(0), east, 15, 1000, 1000, stops: [400]).plan.target(1040),
          closeTo(drive(15, [400], end)(40), 1e-6));
      expect(pathPlan(atM(0), east, 15, 1000, 1000, stops: [400], steps: <double?>[]).plan.target(1040),
          closeTo(drive(15, [400], end)(40), 1e-6));
    });
  });

  group('glideS', () {
    test('takes longer for a longer jump ahead, within bounds; a jump back is quick', () {
      expect(glideS(700, false), greaterThan(glideBaseS));
      expect(glideS(5000, false), glideMaxS);
      expect(glideS(5000, true), glideBaseS);
      expect(glideS(0, false), glideBaseS);
    });
  });

  group('planOnto', () {
    final cum = cumulative(east);

    test('continues from the projected point when the shown point is near the route', () {
      final h = planOnto(atM(300), planOf((_) => 300), 0);
      expect(h.fix, isFalse);
      expect(h.s0, closeTo(300, 1));
      expect(h.off, isNotNull);
      expect(distM(pointAtCum(east, cum, h.s0), atM(300)), lessThan(1));
    });

    test('drives up to a route that starts ahead, in the travel direction', () {
      final h = planOnto((37.97, 23.695), planOf((_) => 0), 0);
      expect(h.fix, isFalse);
      expect(h.s0, 0);
      expect(h.plan.geom.first, (37.97, 23.695));
      expect(h.plan.target(0), closeTo(0.005 / 0.01 * m, 5));
    });

    test('asks for a correction when the shown point is off the route', () {
      final h = planOnto((37.98, 23.705), planOf((_) => 300), 0);
      expect(h.fix, isTrue);
    });
  });

  group('Motion', () {
    test('shows a vehicle for the first time where it is, without an animation', () {
      final mv = Motion();
      mv.update('a', path: east, speed: 8, positionAt: 0, pathSpeeds: null, fix: atM(0), nowS: 0);
      expect(distM(mv.shown('a')!, atM(0)), lessThan(1));
      mv.update('b', path: null, speed: null, positionAt: 0, pathSpeeds: null, fix: atM(50), nowS: 0);
      expect(distM(mv.shown('b')!, atM(50)), lessThan(1));
      expect(mv.shown('nope'), isNull);
    });

    test('a new fix 50 m ahead on the same path: forward, smooth, on the target within a few tau', () {
      final mv = Motion();
      for (var i = 1; i <= 100; i++) {
        mv.update('v', path: east, speed: 8, positionAt: 0, pathSpeeds: null, fix: atM(0), nowS: i / 10);
        mv.step('v', i / 10);
      }
      final shown0 = sAlong(east, mv.shown('v')!);
      expect(shown0, greaterThan(60)); // it moved at pace * speed

      // The next poll: the bus is 50 m further on, and its path starts at the fix.
      final fixAt = shown0 + 50;
      final path = <Pt>[atM(fixAt), east[1], east[2]];
      mv.update('v', path: path, speed: 8, positionAt: 10, pathSpeeds: null, fix: atM(fixAt), nowS: 10);
      expect(distM(mv.shown('v')!, atM(shown0)), lessThan(0.5)); // no jump on the handoff

      var prev = sAlong(east, mv.shown('v')!);
      var gap = fixAt - prev;
      for (var i = 1; i <= 300; i++) {
        final pt = mv.step('v', 10 + i / 10);
        final s = sAlong(east, pt);
        expect(s, greaterThanOrEqualTo(prev - 1e-6)); // never backwards
        expect(s - prev, lessThan(2)); // no jumps
        prev = s;
        final g = fixAt + pace * 8 * i / 10 - s;
        expect(g, lessThanOrEqualTo(gap + 1e-6)); // converges on the target
        gap = g;
      }
      // ~3 tau after the fix it is on the target (50 m closed to under 3 m).
      expect(fixAt + pace * 8 * 30 - prev, lessThan(3));
    });

    test('a fix just ahead of the shown point fades over instead of jumping', () {
      final mv = Motion();
      for (var i = 1; i <= 100; i++) {
        mv.update('v', path: east, speed: 8, positionAt: 0, pathSpeeds: null, fix: atM(0), nowS: i / 10);
        mv.step('v', i / 10);
      }
      final shown0 = sAlong(east, mv.shown('v')!);
      final fixAt = shown0 + 12; // within nearM of the new path's start
      mv.update('v', path: <Pt>[atM(fixAt), east[1], east[2]], speed: 8, positionAt: 10, pathSpeeds: null, fix: atM(fixAt), nowS: 10);
      var prev = sAlong(east, mv.shown('v')!);
      for (var i = 1; i <= 50; i++) {
        final s = sAlong(east, mv.step('v', 10 + i / 10));
        expect(s, greaterThanOrEqualTo(prev - 1e-6));
        expect(s - prev, lessThan(2));
        prev = s;
      }
      expect(prev, greaterThan(fixAt)); // past the fix: the offset faded, the plan goes on
    });

    test('a new fix 5 km away glides, never longer than glideMaxS', () {
      final mv = Motion();
      mv.update('a', path: null, speed: null, positionAt: 0, pathSpeeds: null, fix: atM(0), bearing: 90, nowS: 0);
      mv.update('a', path: null, speed: null, positionAt: 1, pathSpeeds: null, fix: atM(5000), bearing: 90, nowS: 0);
      final early = mv.step('a', 0.1);
      expect(distM(early, atM(0)), lessThan(5)); // no instant snap
      expect(distM(early, atM(5000)), greaterThan(1000));
      mv.step('a', glideBaseS);
      expect(distM(mv.shown('a')!, atM(5000)), greaterThan(1)); // still on its way
      final done = mv.step('a', glideMaxS + 0.01);
      expect(distM(done, atM(5000)), lessThan(1)); // there within glideMaxS
    });

    test('a fix well behind the bearing glides back in glideBaseS', () {
      final mv = Motion();
      mv.update('a', path: null, speed: null, positionAt: 0, pathSpeeds: null, fix: atM(0), bearing: 90, nowS: 0);
      mv.update('a', path: null, speed: null, positionAt: 1, pathSpeeds: null, fix: atM(-400), bearing: 90, nowS: 0);
      expect(distM(mv.step('a', 0.1), atM(0)), lessThan(100)); // back is quick but not a jump
      expect(distM(mv.step('a', glideBaseS + 0.01), atM(-400)), lessThan(1));
    });

    test('step after a 10 s pause snaps to the target', () {
      final mv = Motion();
      mv.update('a', path: east, speed: 8, positionAt: 0, pathSpeeds: null, fix: atM(0), nowS: 0);
      mv.step('a', 0.1);
      final p = mv.step('a', 10.1);
      expect(distM(p, atM(drive(8, <double>[], cumulative(east).last)(10.1))), lessThan(1));
      expect(distM(mv.step('a', 10.2), p), lessThan(1)); // and it goes on from there
    });

    test('the same data again makes no new plan', () {
      final a = Motion(), b = Motion();
      for (var i = 1; i <= 100; i++) {
        final t = i / 10;
        a.update('v', path: east, speed: 8, positionAt: 0, pathSpeeds: null, fix: atM(0), nowS: t);
        // b gets the same data rebuilt each tick: still the same plan.
        b.update('v', path: <Pt>[(37.97, 23.70), (37.97, 23.71), (37.97, 23.72)], speed: 8, positionAt: 0, pathSpeeds: null, fix: atM(0), nowS: t);
        a.step('v', t);
        b.step('v', t);
      }
      expect(a.shown('v'), b.shown('v'));
      expect(distM(a.shown('v')!, atM(80)), lessThan(15));
    });

    test('retain drops the vehicles that left', () {
      final mv = Motion();
      mv.update('a', path: east, speed: 8, positionAt: 0, pathSpeeds: null, fix: atM(0), nowS: 0);
      mv.update('b', path: east, speed: 8, positionAt: 0, pathSpeeds: null, fix: atM(0), nowS: 0);
      mv.retain({'a'});
      expect(mv.shown('a'), isNotNull);
      expect(mv.shown('b'), isNull);
      expect(() => mv.step('b', 1), throwsStateError);
    });
  });
}
