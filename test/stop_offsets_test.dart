// A loop line starts and ends at the same place: its first stop must sit at the start of the shape,
// not at its end (QA: line 732, every stop at 17 km, so a stop 26 stops in looked 0 m from the start).
import 'package:athens_transit/core/geo.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  loopFarFromStart();
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
