import 'package:athens_transit/ui/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // «Τελευταία ενημέρωση 23:08:14»: the Athens clock of a Unix time, to the second.
  test('clockAt reads a Unix time on the Athens clock', () {
    expect(clockAt(DateTime.utc(2026, 11, 11, 21, 8, 14).millisecondsSinceEpoch ~/ 1000), '23:08:14'); // EET, +2
    expect(clockAt(DateTime.utc(2026, 7, 1, 5, 3, 9).millisecondsSinceEpoch ~/ 1000), '08:03:09'); // EEST, +3
  });
}
