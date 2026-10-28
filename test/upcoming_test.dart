import 'package:athens_transit/core/athens_time.dart';
import 'package:athens_transit/core/eta.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('stops already passed (0 or null at the front) are skipped; the last 0 is where the bus is', () {
    expect(firstUpcoming([0, 0, 0, 40, 100]), 2);
    expect(firstUpcoming([null, 0, 30]), 1);
    expect(firstUpcoming([null, null, 30]), 2);
    expect(firstUpcoming([30, 60]), 0);
    expect(firstUpcoming([0, 30]), 0);
    expect(firstUpcoming([]), 0);
    expect(firstUpcoming([null, null]), 2);
  });

  test('the first stop to get off at: not the one the bus is at, but the next one is fine', () {
    expect(firstAlight([0, 0, 40, 100]), 2); // at stops[1]: the next is stops[2]
    expect(firstAlight([30, 60]), 0); // between stops: the next stop still counts
    expect(firstAlight([null, 30]), 1);
    expect(firstAlight([0]), 1); // at the last stop: none left
  });

  test('gaps between the buses of one direction, in stops, from the front bus back', () {
    expect(busGaps([3, 20, 9]), [11, 6]); // 20 ahead, then 9, then 3
    expect(busGaps([5]), isEmpty);
    expect(busGaps([4, 4]), [0]);
    expect(bigGap([4, 5, 14]), 2); // 14 is more than twice the median 5
    expect(bigGap([4, 5, 6]), isNull);
    expect(bigGap([12]), isNull); // one gap: nothing to compare
  });

  test('GTFS times past midnight read as the clock', () {
    expect(gtfsClock('24:30'), '00:30');
    expect(gtfsClock('25:05:00'), '01:05');
    expect(gtfsClock('08:15'), '08:15');
    expect(gtfsClock('x'), 'x');
  });

  test('a slow stretch ahead: metres to the first 200 m step under 10 km/h, within 2 km', () {
    expect(slowAheadM([5.0, 4.0, 2.0, 6.0]), 400); // 2 m/s = 7.2 km/h
    expect(slowAheadM([5.0, null, 5.0]), isNull);
    expect(slowAheadM([1.0]), 0);
    expect(slowAheadM([for (var i = 0; i < 10; i++) 5.0, 1.0]), isNull); // beyond 2 km
    expect(slowAheadM(null), isNull);
  });
}
