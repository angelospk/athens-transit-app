// Contract rev 20: a vehicle with along_m moves along its variant's static shape, past the end of
// its path, from the server's place on the shape (no projection of the fix on loops).

import 'package:athens_transit/core/geo.dart';
import 'package:athens_transit/core/models.dart';
import 'package:athens_transit/core/motion.dart';
import 'package:flutter_test/flutter_test.dart';

final m = distM((37.97, 23.70), (37.97, 23.71)); // metres per 0.01° lon
Pt atM(double metres) => (37.97, 23.70 + (metres / m) * 0.01);
// A straight 10 km shape, a point every 500 m.
final long = [for (var i = 0; i <= 20; i++) atM(i * 500.0)];
ShapeRoute routeOf(List<Pt> shape, {double? lengthM}) =>
    ShapeRoute(shape: shape, cum: cumulative(shape), lengthM: lengthM, stopS: const []);

double sAlong(List<Pt> geom, Pt p) => projectCum(geom, cumulative(geom), p).s;

void main() {
  test('Variant and Vehicle read length_m and along_m', () {
    final v = Variant.fromJson({'headsign': 'X', 'direction': 0, 'shape': [[37.97, 23.7], [37.97, 23.71]], 'length_m': 876, 'stops': []});
    expect(v.lengthM, 876);
    expect(Variant.fromJson({'headsign': 'X', 'direction': 0, 'shape': [], 'stops': []}).lengthM, isNull);
    final c = Vehicle.fromJson({'id': '1', 'lat': 37.97, 'lon': 23.7, 'position_at': 5, 'along_m': 4210});
    expect(c.alongM, 4210);
    expect(Vehicle.fromJson({'id': '1', 'lat': 37.97, 'lon': 23.7, 'position_at': 5}).alongM, isNull);
  });

  group('alongS', () {
    test('scales along_m by the client length over length_m', () {
      final r = routeOf(long, lengthM: cumulative(long).last * 1.01);
      expect((alongS(r, 5050, atM(5000))! - 5000).abs(), lessThan(2));
    });

    test('ignores along_m that does not fit the shape or the fix', () {
      final r = routeOf(long);
      expect(alongS(r, 5000, atM(5600)), isNull); // 600 m from the fix
      expect(alongS(r, 20000, atM(10000)), isNull); // past the end
      expect(alongS(r, 10020, atM(10000)), closeTo(r.cum.last, 0.5)); // rounding: clamped
      expect(alongS(routeOf(long, lengthM: 0), 5000, atM(5000)), closeTo(5000, 2)); // no length: factor 1
    });
  });

  group('Motion with along_m', () {
    test('drives on along the shape past the end of its path', () {
      final mv = Motion();
      final path = [atM(1000), atM(1300)];
      Pt? p;
      for (var i = 0; i <= 1500; i++) {
        final t = i / 10;
        mv.update('v', path: path, speed: 10, positionAt: 0, pathSpeeds: null, fix: atM(1000), nowS: t,
            route: routeOf(long), alongM: 1000);
        p = mv.step('v', t);
      }
      expect(sAlong(long, p!), greaterThan(2000)); // 0.85 x 10 m/s x 150 s on, not stopped at 1300
    });

    test('without the shape it stops at the end of its path, as before', () {
      final mv = Motion();
      final path = [atM(1000), atM(1300)];
      Pt? p;
      for (var i = 0; i <= 1500; i++) {
        final t = i / 10;
        mv.update('v', path: path, speed: 10, positionAt: 0, pathSpeeds: null, fix: atM(1000), nowS: t, alongM: 1000);
        p = mv.step('v', t);
      }
      expect(sAlong(long, p!), lessThan(1301));
    });

    test('takes the shape as soon as it is loaded, for the same fix', () {
      final mv = Motion();
      final path = [atM(1000), atM(1300)];
      mv.update('v', path: path, speed: 10, positionAt: 0, pathSpeeds: null, fix: atM(1000), nowS: 0, alongM: 1000);
      mv.step('v', 0);
      Pt? p;
      for (var i = 1; i <= 1500; i++) {
        final t = i / 10;
        mv.update('v', path: path, speed: 10, positionAt: 0, pathSpeeds: null, fix: atM(1000), nowS: t,
            route: t >= 5 ? routeOf(long) : null, alongM: 1000);
        p = mv.step('v', t);
      }
      expect(sAlong(long, p!), greaterThan(2000));
    });

    test('walks path_speeds and stands at the shape end', () {
      final mv = Motion();
      Pt? p;
      for (var i = 0; i <= 1700; i++) {
        final t = i / 10;
        mv.update('v', path: null, speed: 12, positionAt: 0, pathSpeeds: const [5, null], fix: atM(9000), nowS: t,
            route: routeOf(long), alongM: 9000);
        p = mv.step('v', t);
      }
      expect(sAlong(long, p!), greaterThan(9990));
      expect(sAlong(long, p), lessThanOrEqualTo(10000 + 1e-6));
    });

    test('glides on to a new fix a little behind the guess, never backwards', () {
      final mv = Motion();
      final r = routeOf(long);
      for (var i = 0; i <= 300; i++) {
        mv.update('v', path: null, speed: 10, positionAt: 0, pathSpeeds: null, fix: atM(1000), nowS: i / 10, route: r, alongM: 1000);
        mv.step('v', i / 10);
      }
      var prev = sAlong(long, mv.shown('v')!); // ~255 m on
      for (var i = 1; i <= 300; i++) {
        final t = 30 + i / 10;
        mv.update('v', path: null, speed: 10, positionAt: 30, pathSpeeds: null, fix: atM(1230), nowS: t, route: r, alongM: 1230);
        final s = sAlong(long, mv.step('v', t));
        expect(s, greaterThanOrEqualTo(prev - 1e-6));
        prev = s;
      }
      expect(prev, greaterThan(1300));
    });

    test('takes the pass along_m names on an out-and-back shape', () {
      final back = [atM(0), atM(1000), atM(0)];
      final mv = Motion();
      Pt? p;
      for (var i = 0; i <= 200; i++) {
        mv.update('v', path: null, speed: 5, positionAt: 0, pathSpeeds: null, fix: atM(300), nowS: i / 10,
            route: routeOf(back), alongM: 1700);
        p = mv.step('v', i / 10);
      }
      expect(p!.$2, lessThan(atM(300).$2)); // heading west, back to the start
    });
  });
}
