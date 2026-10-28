// A loop line starts and ends at the same place: its first stop must sit at the start of the shape,
// not at its end (QA: line 732, every stop at 17 km, so a stop 26 stops in looked 0 m from the start).
import 'package:athens_transit/core/geo.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
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
