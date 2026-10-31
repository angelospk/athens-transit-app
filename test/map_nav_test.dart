import 'package:athens_transit/ui/map_sel.dart';
import 'package:athens_transit/ui/stop_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized(); // showOnMap asks navKey for the pages over the map
  const stop = StopRef(name: 'ΣΧΟΛΗ', lat: 38, lon: 23.7, lines: ['040']);
  setUp(() => mapSel.value = null);

  test('back walks through what was opened, then closes', () {
    mapSel.value = const StopSel(stop);
    mapSel.value = const BusSel('040', '1', stop: stop);
    mapSel.value = const LineSel('040');
    expect(canMapBack(), isTrue);
    mapBack();
    expect(mapSel.value, isA<BusSel>());
    mapBack();
    expect(mapSel.value, isA<StopSel>());
    expect(canMapBack(), isFalse);
    mapBack();
    expect(mapSel.value, isNull);
  });

  test('a new direction of the same line replaces, it is not a step back', () {
    mapSel.value = const StopSel(stop);
    mapSel.value = const LineSel('040');
    mapSel.value = const LineSel('040', variants: {'a'});
    mapBack();
    expect(mapSel.value, isA<StopSel>());
  });

  test('closing forgets the history', () {
    mapSel.value = const StopSel(stop);
    mapSel.value = const LineSel('040');
    mapSel.value = null;
    mapSel.value = const LineSel('550');
    expect(canMapBack(), isFalse);
  });

  test('a bus opened from a notification goes back to its stop', () {
    mapSel.value = const BusSel('040', '1', stop: stop);
    expect(canMapBack(), isTrue);
    mapBack();
    expect((mapSel.value as StopSel).stop.name, 'ΣΧΟΛΗ');
  });

  test('«Πίσω» is named after the level before; the first level goes back home', () {
    mapSel.value = const StopSel(stop);
    expect(backLabel(), 'Κοντά σου');
    mapSel.value = const LineSel('040');
    expect(backLabel(), 'Σχολη');
    mapSel.value = const BusSel('040', '1');
    expect(backLabel(), 'Γραμμή 040');
  });

  // The app's navigator: the map first, the pages the menu opens over it.
  Widget app() => MaterialApp(navigatorKey: navKey, navigatorObservers: [pageLog], home: const Text('map'));
  Future<void> page(WidgetTester t, String name) async {
    navKey.currentState!.push(MaterialPageRoute<void>(settings: RouteSettings(name: name), builder: (_) => Text('page $name')));
    await t.pumpAndSettle();
  }

  testWidgets('a jump from pages to the map goes back to those pages, in order', (t) async {
    await t.pumpWidget(app());
    await page(t, 'Διαδρομή');
    await page(t, 'Βήματα');
    mapSel.value = const LineSel('550'); // open before: the jump replaces it, not a step back
    showOnMap(const StopSel(stop));
    await t.pumpAndSettle();
    expect(find.text('map'), findsOneWidget);
    expect(backLabel(), 'Βήματα');
    mapSel.value = const BusSel('040', '1', stop: stop);
    mapBack();
    expect(mapSel.value, isA<StopSel>());
    mapBack();
    await t.pumpAndSettle();
    expect(mapSel.value, isNull);
    expect(find.text('page Βήματα'), findsOneWidget);
    navKey.currentState!.pop();
    await t.pumpAndSettle();
    expect(find.text('page Διαδρομή'), findsOneWidget);
    navKey.currentState!.pop();
    await t.pumpAndSettle();
    expect(find.text('map'), findsOneWidget);
    expect(backLabel(), 'Κοντά σου'); // the way back is used once
  });

  testWidgets('a jump from the map itself has no pages to go back to', (t) async {
    await t.pumpWidget(app());
    showOnMap(const StopSel(stop));
    await t.pumpAndSettle();
    expect(canMapBack(), isFalse);
    expect(backLabel(), 'Κοντά σου');
  });

  testWidgets('closing the sheet forgets the way back to the pages', (t) async {
    await t.pumpWidget(app());
    await page(t, 'Αγαπημένα');
    showOnMap(const StopSel(stop));
    await t.pumpAndSettle();
    mapSel.value = null;
    mapSel.value = const StopSel(stop);
    expect(canMapBack(), isFalse);
    mapBack();
    await t.pumpAndSettle();
    expect(find.text('page Αγαπημένα'), findsNothing);
  });

  testWidgets('a reopened page gets the state it kept; a page opened anew gets none', (t) async {
    Object? got = 'unset';
    Widget keeping(String name) => Builder(builder: (c) {
          got = reopenedState(c);
          keepPageState(c, 'state of $name');
          return Text('page $name');
        });
    await t.pumpWidget(app());
    navKey.currentState!.push(MaterialPageRoute<void>(settings: const RouteSettings(name: 'A'), builder: (_) => keeping('A')));
    await t.pumpAndSettle();
    expect(got, isNull);
    showOnMap(const StopSel(stop));
    await t.pumpAndSettle();
    // Another page of the same kind, opened from the map, keeps its own state.
    navKey.currentState!.push(MaterialPageRoute<void>(settings: const RouteSettings(name: 'B'), builder: (_) => keeping('B')));
    await t.pumpAndSettle();
    expect(got, isNull);
    navKey.currentState!.pop();
    await t.pumpAndSettle();
    mapBack();
    await t.pumpAndSettle();
    expect(find.text('page A'), findsOneWidget);
    expect(got, 'state of A');
  });

  test('back on «Αγαπημένα» goes to «Κοντά σου» before it leaves the app', () {
    homeTab.value = 1;
    expect(atHome(), isFalse);
    mapBack();
    expect(homeTab.value, 0);
    expect(atHome(), isTrue);
  });
}
