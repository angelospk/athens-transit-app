// «Απέναντι στάση»: the stop card links the stop across the road when OASA gives it another name (a loop
// line's «1η/2η ΚΥΚΛΙΚΟΣ ΚΟΜΒΟΣ», 54 m apart). Same-name stops within 200 m are one card already
// (linesAt, stopIdsNear). As in the web (twins, v0.2.6): another name within 100 m, not the next stop
// on any variant, where a line of both runs the other way (bearings more than 120° apart).
import 'package:athens_transit/core/models.dart';
import 'package:athens_transit/core/nearby.dart';
import 'package:flutter_test/flutter_test.dart';

// A loop line: out along the north side, round at ΑΥΛΑΚΙ, back along the south side.
// 1 and 3: the two sides of one road (~58 m); 4: the next stop after 1, the same way.
const _s = [
  ('ΑΦΕΤΗΡΙΑ', 37.9, 23.9),
  ('1η ΚΟΜΒΟΣ', 37.9005, 23.905),
  ('ΑΥΛΑΚΙ', 37.9, 23.92),
  ('2η ΚΟΜΒΟΣ', 37.9, 23.9052),
  ('ΕΠΟΜΕΝΗ', 37.9005, 23.906),
  ('ΑΛΛΗ', 37.9004, 23.9051), // close to 1, on another line only
];

TripIndex _ix({List<(String, double, double)> s = _s}) => TripIndex(v: 't', s: s, l: {
      'L': {'v': [0, 1, 4, 2, 3, 0]},
      'M': {'m': [5, 4]},
    });

void main() {
  test('the other side of the road, by another name', () {
    final a = acrossStop(_ix(), '1η ΚΟΜΒΟΣ', 37.9005, 23.905)!;
    expect(a.name, '2η ΚΟΜΒΟΣ');
    expect((a.lat, a.lon), (37.9, 23.9052));
    expect(a.m, inInclusiveRange(40, 70));
    expect(acrossStop(_ix(), '2η ΚΟΜΒΟΣ', 37.9, 23.9052)!.name, '1η ΚΟΜΒΟΣ');
  });

  test('the next stop the same way is not across the road', () {
    expect(acrossStop(_ix(), 'ΕΠΟΜΕΝΗ', 37.9005, 23.906)?.name, isNot('1η ΚΟΜΒΟΣ'));
  });

  test('no line of both: not across the road, however close', () {
    expect(acrossStop(_ix(), 'ΑΛΛΗ', 37.9004, 23.9051), isNull);
  });

  test('a stop of the same name is part of this card already', () {
    final s = [..._s]..[3] = ('1η ΚΟΜΒΟΣ', 37.9, 23.9052);
    expect(acrossStop(_ix(s: s), '1η ΚΟΜΒΟΣ', 37.9005, 23.905), isNull);
  });

  test('farther than 100 m: not across the road', () {
    final s = [..._s]..[3] = ('2η ΚΟΜΒΟΣ', 37.8985, 23.9052); // ~225 m south
    expect(acrossStop(_ix(s: s), '1η ΚΟΜΒΟΣ', 37.9005, 23.905), isNull);
  });

  test('a name the index does not know: none', () {
    expect(acrossStop(_ix(), 'ΚΑΜΙΑ', 37.9005, 23.905), isNull);
  });
}
