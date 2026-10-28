import 'package:athens_transit/core/rules.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const r = Rule(id: '1', line: '040', variant: 'a', stopIndex: 3, stopId: 's', stopName: 'ΣΥΝΤΑΓΜΑ', mode: AlertMode.stops, n: 1, days: 0, startMin: 0, endMin: 0, untilS: 9);
  const h = RuleHit(ruleId: '1', line: '040', vehicleId: 'v', stopsLeft: 1, etaS: 120, delayS: null);

  test('the kind survives json; an old rule without it is an arrival', () {
    final ride = r.copyWith(kind: RuleKind.ride);
    expect(Rule.fromJson(ride.toJson()), ride);
    expect(Rule.fromJson(r.toJson()).kind, RuleKind.arrive);
    expect(r.toJson().containsKey('kind'), isFalse);
  });

  test('the words follow the kind', () {
    expect(ruleHitText(r, h, 'ΣΥΝΤΑΓΜΑ').$1, '040 → ΣΥΝΤΑΓΜΑ');
    expect(ruleHitText(r.copyWith(kind: RuleKind.ride), h, 'ΣΥΝΤΑΓΜΑ').$1, 'Κατέβα στην επόμενη');
    expect(ruleHitText(r.copyWith(kind: RuleKind.leave), h, 'ΣΥΝΤΑΓΜΑ').$1, 'Φύγε τώρα για το 040');
  });

  test('a rule for one bus ignores the others of the line', () {
    final one = r.copyWith(vehicle: 'mine');
    expect(Rule.fromJson(one.toJson()).vehicle, 'mine');
  });
}
