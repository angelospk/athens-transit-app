import 'package:athens_transit/core/geo.dart';
import 'package:athens_transit/core/leave.dart';
import 'package:athens_transit/core/models.dart';
import 'package:athens_transit/core/route_steps.dart';
import 'package:athens_transit/core/trip.dart';
import 'package:flutter_test/flutter_test.dart';

// Stops on a north-south street, ~111 m apart per 0.001°.
const ix = TripIndex(v: '', s: [
  ('ΑΡΧΗ', 38.000, 23.700), // 0
  ('ΜΕΣΗ', 38.010, 23.700), // 1
  ('ΑΛΛΑΓΗ', 38.020, 23.700), // 2
  ('ΑΠΕΝΑΝΤΙ', 38.020, 23.702), // 3: across the street from 2
  ('ΤΕΛΟΣ', 38.030, 23.702), // 4
  ('ΤΕΡΜΑ', 38.040, 23.702), // 5
], l: {
  '040': {'v1': [0, 1, 2]},
  '550': {'v2': [3, 4, 5]},
});

void main() {
  test('one bus: walk to the stop, ride, walk to the end', () {
    const from = [(37.997, 23.700)], to = [(38.022, 23.700)];
    final walkIn = distM(from.first, (38.000, 23.700)), walkOut = distM(to.first, (38.020, 23.700));
    final v = TripVariant(id: 'v1', i: 0, j: 2, from: 0, to: 2, walk: walkIn + walkOut, stops: 2, ride: 2224, min: 0);
    final steps = directSteps(ix, TripLine(line: '040', walk: v.walk, stops: 2, min: 0, variants: [v]), from: from, to: to);
    expect(steps.map((s) => s.kind), [StepKind.walk, StepKind.bus, StepKind.walk]);
    expect(steps[0].to, 'ΑΡΧΗ');
    expect(steps[0].min, walkMinutes(walkIn));
    final bus = steps[1];
    expect((bus.line, bus.variant, bus.from, bus.to, bus.toward, bus.stops, bus.i, bus.j), ('040', 'v1', 'ΑΡΧΗ', 'ΑΛΛΑΓΗ', 'ΑΛΛΑΓΗ', 2, 0, 2));
    expect(bus.fromAt, (38.000, 23.700));
    expect(bus.min, rideMinutes(2224).round());
    expect(steps[2].from, 'ΑΛΛΑΓΗ');
    expect(steps[2].toAt, isNull); // the destination itself
  });

  test('no walk step when the place is the stop', () {
    const from = [(38.000, 23.700)], to = [(38.020, 23.700)];
    const v = TripVariant(id: 'v1', i: 0, j: 2, from: 0, to: 2, walk: 0, stops: 2, ride: 2224, min: 0);
    final steps = directSteps(ix, const TripLine(line: '040', walk: 0, stops: 2, min: 0, variants: [v]), from: from, to: to);
    expect(steps.map((s) => s.kind), [StepKind.bus]);
  });

  test('a change: ride, walk across, wait, ride', () {
    const from = [(38.000, 23.700)], to = [(38.040, 23.702)];
    const c = TripTransfer(
      legs: [
        TripLeg(line: '040', id: 'v1', i: 0, j: 2, from: 0, to: 2, stops: 2, ride: 2224),
        TripLeg(line: '550', id: 'v2', i: 0, j: 2, from: 3, to: 5, stops: 2, ride: 2224),
      ],
      walk: 0,
      xfer: 175,
      min: 0,
    );
    final steps = transferSteps(ix, c, from: from, to: to);
    expect(steps.map((s) => s.kind), [StepKind.bus, StepKind.walk, StepKind.bus]);
    expect((steps[1].from, steps[1].to, steps[1].min), ('ΑΛΛΑΓΗ', 'ΑΠΕΝΑΝΤΙ', walkMinutes(175)));
    expect(steps[2].wait, xferMin.round());
    expect((steps[2].line, steps[2].from, steps[2].to), ('550', 'ΑΠΕΝΑΝΤΙ', 'ΤΕΡΜΑ'));
  });

  test('the total adds every step and the wait', () {
    const from = [(38.000, 23.700)], to = [(38.040, 23.702)];
    const c = TripTransfer(
      legs: [
        TripLeg(line: '040', id: 'v1', i: 0, j: 2, from: 0, to: 2, stops: 2, ride: 2224),
        TripLeg(line: '550', id: 'v2', i: 0, j: 2, from: 3, to: 5, stops: 2, ride: 2224),
      ],
      walk: 0,
      xfer: 175,
      min: 0,
    );
    final steps = transferSteps(ix, c, from: from, to: to);
    expect(totalMinutes(steps), steps.fold<int>(0, (a, s) => a + s.min + s.wait));
  });
}
