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
}

