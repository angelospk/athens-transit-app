import 'dart:convert';
import 'dart:io';

import 'package:athens_transit/core/rail.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final sub = Suburban.fromJson(jsonDecode(File('assets/suburban.json').readAsStringSync()) as Map<String, dynamic>);

  test('the suburban table: corridors in line order, stations with places', () {
    expect(sub.corridors.keys, containsAll(['PIRAIR', 'KIATO', 'CHALKIDA']));
    final k = sub.corridors['KIATO']!;
    expect(sub.stations[k.stations.first]!.name, 'Πειραιάς');
    expect(sub.stations[k.stations.last]!.name, 'Κιάτο');
    for (final s in sub.stations.values) {
      expect(s.lat, inInclusiveRange(37.5, 38.6), reason: s.name);
    }
  });

  test('a departure goes to the end of its corridor in the direction of its next stop', () {
    final pir = sub.byName('Πειραιάς')!;
    expect(sub.towards(pir.id, 'Λεύκα'), {'Κιάτο', 'Αεροδρόμιο'}); // both lines leave Piraeus through Λεύκα
    final rouf = sub.byName('Ρουφ')!;
    expect(sub.towards(rouf.id, 'Ταύρος'), {'Πειραιάς'});
    expect(sub.towards(rouf.id, 'Κανένας'), isEmpty);
  });

  test('the board writes "Άγιοι Ανάργυροι" for our "Αγ. Ανάργυροι"', () {
    expect(sub.byName('Άγιοι Ανάργυροι')?.name, 'Αγ. Ανάργυροι');
    final ath = sub.byName('Αθήνα')!;
    expect(sub.towards(ath.id, 'Άγιοι Ανάργυροι'), isNotEmpty);
    for (final n in ['Σιδηροδρομικό Κέντρο Αχαρνών', 'Ρέντης', 'Πύργος Βασιλίσσης']) {
      expect(sub.byName(n), isNotNull, reason: n);
    }
  });

  test('railway.gov.gr departures parse; times are UTC; a delay in minutes', () {
    final ds = parseRailDepartures(jsonDecode(File('test/fixtures/rail-departures.json').readAsStringSync()));
    expect(ds, isNotEmpty);
    expect(ds.first.train, '1300');
    expect(ds.first.next, 'Λεύκα');
    expect(ds.first.scheduled.isUtc, isTrue);
    expect(ds.first.delayMin, 0);
    final late = parseRailDepartures({
      'departures': [
        {'trainNumber': '1', 'to': 'Χ', 'scheduledTime': '2026-10-28T08:00:00.000Z', 'actualTime': '2026-10-28T08:07:00.000Z', 'status': 'delayed', 'delay': 7, 'platform': '2'}
      ]
    });
    expect(late.single.delayMin, 7);
    expect(late.single.expected, DateTime.utc(2026, 10, 28, 8, 7));
    expect(late.single.platform, '2');
    expect(late.single.cancelled, isFalse);
  });
}
