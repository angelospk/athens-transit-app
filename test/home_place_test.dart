import 'package:athens_transit/data/store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('an approximate home snaps to a ~250 m grid: near home, not the door', () {
    final a = approxPoint((37.97553, 23.73481));
    final b = approxPoint((37.97561, 23.73499)); // next door
    expect(a, b);
    expect((a.$1 - 37.97553).abs(), lessThan(.0013));
    expect((a.$2 - 23.73481).abs(), lessThan(.0013));
  });

  test('«Σπίτι» is a place that survives a restart; clearing it removes it', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final s = AppStore(prefs);
    expect(s.home, isNull);
    s.setHome(const SavedPlace(label: 'Παγκράτι', lat: 37.968, lon: 23.744, approx: true));
    final back = AppStore(prefs).home!;
    expect((back.label, back.lat, back.lon, back.approx), ('Παγκράτι', 37.968, 23.744, true));
    s.setHome(null);
    expect(AppStore(prefs).home, isNull);
  });

  test('without a place, the old «Σπίτι» stop stands in for it', () async {
    SharedPreferences.setMockInitialValues({});
    final s = AppStore(await SharedPreferences.getInstance());
    expect(s.homePt, isNull);
    s.addFav(const FavStop(name: 'ΣΥΝΤΑΓΜΑ', lat: 37.975, lon: 23.735, place: Place.home, lines: ['040']));
    expect(s.homePt, (37.975, 23.735));
    s.setHome(const SavedPlace(label: 'Παγκράτι', lat: 37.968, lon: 23.744, approx: true));
    expect(s.homePt, (37.968, 23.744)); // the place wins
  });

  test('removing the last line of mine shows all buses again: the map has no switch without lines', () async {
    SharedPreferences.setMockInitialValues({});
    final s = AppStore(await SharedPreferences.getInstance());
    s.toggleMyLine('040');
    s.setOnlyMine(true);
    s.toggleMyLine('040');
    expect(s.onlyMine, isFalse);
  });
}
