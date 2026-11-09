import 'package:athens_transit/core/models.dart';
import 'package:athens_transit/core/nearby.dart';
import 'package:athens_transit/ui/theme.dart';
import 'package:athens_transit/ui/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// Two ΚΑΤΕΧΑΚΗ stops across the road (25 m apart), a ΚΑΤΕΧΑΚΗ far away, and a stop with no direction data.
final _ix = TripIndex.fromJson({
  'v': 't',
  's': [
    ['ΚΑΤΕΧΑΚΗ', 37.99300, 23.77600, '1'],
    ['ΚΑΤΕΧΑΚΗ', 37.99320, 23.77610, '2'],
    ['ΣΥΝΤΑΓΜΑ', 37.97550, 23.73480, '3'],
    ['ΚΑΤΕΧΑΚΗ', 38.05000, 23.80000, '4'],
  ],
  'l': {
    '140': {'a': [0, 2], 'b': [2, 1]},
    '242': {'a': [0]},
    '409': {'a': [3]},
  },
  'd': {
    'n': ['Μουσείο', 'ΕΡΥΘΡΟΣ ΣΤΑΥΡΟΣ', 'ΠΟΛΥΓΩΝΟ'],
    's': [
      [225, 0, 1],
      [45, 2],
      [],
      [null, 2],
    ],
  },
});

void main() {
  test('trips.json `d`: the bearing and up to two terminus names, in capitals without accents', () {
    final a = towardOf(_ix, 0)!;
    expect(a.bearing, 225);
    expect(a.names, ['ΜΟΥΣΕΙΟ', 'ΕΡΥΘΡΟΣ ΣΤΑΥΡΟΣ']);
    expect(towardText(a), 'προς ΜΟΥΣΕΙΟ · ΕΡΥΘΡΟΣ ΣΤΑΥΡΟΣ');
    expect(towardOf(_ix, 2), isNull); // no data
    expect(towardOf(_ix, 3)!.bearing, isNull); // names only, no arrow
    expect(towardOf(_ix, 99), isNull);
    // A trips.json from before `d`: nothing, no crash.
    final old = TripIndex.fromJson({'v': 't', 's': [['Α', 37.9, 23.7, '1']], 'l': {}});
    expect(towardOf(old, 0), isNull);
  });

  test('the stop at a point: the same-name stop nearest to it, within 40 m', () {
    expect(towardAt(_ix, 'ΚΑΤΕΧΑΚΗ', 37.99301, 23.77601)!.bearing, 225);
    expect(towardAt(_ix, 'ΚΑΤΕΧΑΚΗ', 37.99319, 23.77609)!.bearing, 45); // the other side of the road
    expect(towardAt(_ix, 'ΚΑΤΕΧΑΚΗ', 37.98000, 23.77600), isNull); // 1.5 km away
    expect(towardAt(_ix, 'ΣΥΝΤΑΓΜΑ', 37.99300, 23.77600), isNull); // another name here
  });

  test('search: each side of the road on its own row, with its own lines', () {
    final hits = stopHits(_ix, 'κατεχ');
    expect(hits, [0, 1, 3]); // both twins, then the far ΚΑΤΕΧΑΚΗ
    expect(linesOfStop(_ix, 0), ['140', '242']);
    expect(linesOfStop(_ix, 1), ['140']);
    expect(stopHits(_ix, 'κατεχ', max: 2), [0, 1]);
  });

  testWidgets('the direction row: an arrow turned to the bearing, then «προς …»', (t) async {
    await t.pumpWidget(MaterialApp(theme: buildTheme(Brightness.light), home: Scaffold(body: TowardRow(towardOf(_ix, 0)!))));
    expect(find.text('προς ΜΟΥΣΕΙΟ · ΕΡΥΘΡΟΣ ΣΤΑΥΡΟΣ'), findsOneWidget);
    final turn = t.widget<Transform>(find.descendant(of: find.byType(TowardRow), matching: find.byType(Transform)).first);
    expect(turn.transform.getRotation().determinant(), closeTo(1, 1e-9));
    await t.pumpWidget(MaterialApp(theme: buildTheme(Brightness.light), home: Scaffold(body: TowardRow(towardOf(_ix, 3)!))));
    expect(find.descendant(of: find.byType(TowardRow), matching: find.byType(Transform)), findsNothing); // no bearing: no arrow
    expect(find.text('προς ΠΟΛΥΓΩΝΟ'), findsOneWidget);
  });
}
