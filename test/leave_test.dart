import 'package:athens_transit/core/leave.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('walk minutes: straight line ×1.3 at 75 m/min, rounded up, at least 1', () {
    expect(walkMinutes(0), 1);
    expect(walkMinutes(300), 6); // 390 m
    expect(walkMinutes(577), 11); // 750.1 m
  });

  test('leave in: eta less walk and margin', () {
    expect(leaveInMinutes(9 * 60, 4, 3), 2);
    expect(leaveInMinutes(5 * 60 + 59, 4, 3), -2);
  });
}
