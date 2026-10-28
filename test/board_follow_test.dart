// «Ακολούθησέ με» with the app closed: the service samples the phone every 10 s and the buses of the
// followed line as polled (fixes up to a minute old, moved on along their path to the phone's time).
import 'package:athens_transit/core/board.dart';
import 'package:athens_transit/core/geo.dart';
import 'package:athens_transit/core/models.dart';
import 'package:athens_transit/core/rules.dart';
import 'package:flutter_test/flutter_test.dart';

// A street due north: 0.001° of latitude is ~111 m.
Pt north(double m) => (38.0 + m / 111195.0, 23.7);

Vehicle bus(String id, double m, int at, {double speed = 8, String variant = 'v1'}) => Vehicle(
      id: id,
      lat: north(m).$1,
      lon: north(m).$2,
      positionAt: at,
      variant: variant,
      speed: speed,
      path: [north(m), north(m + 5000)],
    );

const rule = Rule(
  id: 'f1', line: '040', variant: 'v1', stopIndex: 9, stopId: 's9', stopName: 'ΤΕΛΟΣ', mode: AlertMode.stops, n: 1,
  days: 0, startMin: 0, endMin: 0, untilS: 9999999999, kind: RuleKind.board,
);

void main() {
  test('a bus fix moves on along its path to the asked time', () {
    final v = bus('a', 0, 100);
    expect(distM(predictAt(v, 130), north(240)), lessThan(1));
    expect(distM(predictAt(v, 100), north(0)), lessThan(1));
    expect(distM(predictAt(v, 5000), north(5000)), lessThan(1)); // not past the path's end
  });

  test('riding with a bus polled every 30 s: boarded within about a minute and a half', () {
    final w = BoardWatch();
    String? got;
    for (var t = 0; t <= 120 && got == null; t += 10) {
      final polled = t - t % 30; // the bus's newest fix
      got = w.add(t, north(8.0 * t + 10), [bus('a', 8.0 * polled, polled), bus('b', 8.0 * polled + 900, polled)]);
      if (got != null) expect(t, lessThanOrEqualTo(90));
    }
    expect(got, 'a');
  });

  test('walking beside the street or standing at the stop: not boarded', () {
    final w = BoardWatch();
    for (var t = 0; t <= 180; t += 10) {
      final polled = t - t % 30;
      expect(w.add(t, (north(1.4 * t).$1, 23.703), [bus('a', 8.0 * polled, polled)]), isNull); // 260 m east
    }
    final s = BoardWatch();
    for (var t = 0; t <= 180; t += 10) {
      final polled = t - t % 30;
      expect(s.add(t, north(0), [bus('a', 8.0 * polled, polled)]), isNull);
    }
  });

  test('a gap in the phone fixes starts the minute together again', () {
    final w = BoardWatch();
    for (var t = 0; t <= 40; t += 10) {
      expect(w.add(t, north(8.0 * t), [bus('a', 8.0 * t, t)]), isNull);
    }
    expect(w.add(100, north(800), [bus('a', 800, 100)]), isNull); // 60 s without a fix
  });

  test('a followed trip: looking for the bus until boarded, then the ride alert of that bus', () {
    expect(watchedRules([rule], const {}), isEmpty); // nothing to alert yet
    expect(lookingRules([rule], const {}).map((r) => r.id), ['f1']);
    final ride = watchedRules([rule], const {'f1': 'a'}).single;
    expect((ride.kind, ride.vehicle, ride.stopIndex), (RuleKind.ride, 'a', 9));
    expect(lookingRules([rule], const {'f1': 'a'}), isEmpty);
    final plain = rule.copyWith(id: 'r2', kind: RuleKind.arrive);
    expect(watchedRules([plain], const {}).single.id, 'r2');
    expect(Rule.fromJson(rule.toJson()).kind, RuleKind.board);
  });
}
