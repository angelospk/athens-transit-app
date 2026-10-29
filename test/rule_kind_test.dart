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

  test('lateMin survives json; an old rule has none and writes no key', () {
    final late = r.copyWith(lateMin: 7);
    expect(Rule.fromJson(late.toJson()), late);
    expect(Rule.fromJson(late.toJson()).lateMin, 7);
    expect(r.toJson().containsKey('lateMin'), isFalse);
    expect(Rule.fromJson(r.toJson()).lateMin, isNull);
  });

  test('a delay hit says how late, whatever the kind', () {
    const late = RuleHit(ruleId: '1', line: '040', vehicleId: 'v', stopsLeft: 4, etaS: 600, delayS: 420, late: true);
    final (title, body) = ruleHitText(r.copyWith(lateMin: 5), late, 'ΣΥΝΤΑΓΜΑ');
    expect(title, '040 αργεί 7′');
    expect(body, contains('ΣΥΝΤΑΓΜΑ'));
    expect(body, contains('~10′'));
    expect(ruleHitText(r.copyWith(kind: RuleKind.leave, lateMin: 5), late, 'ΣΥΝΤΑΓΜΑ').$1, '040 αργεί 7′');
    expect(h.late, isFalse);
  });

  test('a rule for one bus ignores the others of the line', () {
    final one = r.copyWith(vehicle: 'mine');
    expect(Rule.fromJson(one.toJson()).vehicle, 'mine');
  });

  test('a bell is filled while a rule for the line at the stop is set', () {
    expect(hasAlert([r], '040', 'ΣΥΝΤΑΓΜΑ', 9), isTrue); // one-off, not yet over
    expect(hasAlert([r], '040', 'ΣΥΝΤΑΓΜΑ', 10), isFalse); // over
    expect(hasAlert([r], '209', 'ΣΥΝΤΑΓΜΑ', 9), isFalse); // another line
    expect(hasAlert([r], '040', 'ΑΚΡΟΠΟΛΗ', 9), isFalse); // another stop
    const weekly = Rule(id: '2', line: '040', variant: 'a', stopIndex: 3, stopId: 's', stopName: 'ΣΥΝΤΑΓΜΑ', mode: AlertMode.minutes, n: 5, days: 1, startMin: 480, endMin: 520);
    expect(hasAlert([weekly], '040', 'ΣΥΝΤΑΓΜΑ', 1 << 40), isTrue); // weekly: set at any hour
    expect(hasAlert([r.copyWith(enabled: false)], '040', 'ΣΥΝΤΑΓΜΑ', 9), isFalse);
    expect(hasAlert([r.copyWith(kind: RuleKind.ride)], '040', 'ΣΥΝΤΑΓΜΑ', 9), isFalse); // getting off is not a bell
  });
}
