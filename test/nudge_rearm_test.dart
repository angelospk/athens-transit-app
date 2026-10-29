import 'package:athens_transit/background/service.dart';
import 'package:athens_transit/data/store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

// The evening alarm follows the setting and the home stop: the store listener re-arms it each time
// either one changes whether the alarm is wanted.
void main() {
  late AppStore store;
  var calls = 0;
  const home = FavStop(name: 'ΣΥΝΤΑΓΜΑ', lat: 37.975, lon: 23.735, place: Place.home, lines: ['040']);

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    store = AppStore(await SharedPreferences.getInstance());
    calls = 0;
    store.addListener(AlertService.nudgeListener(store, () => calls++));
  });

  test('the setting turned off and on again re-arms the alarm each time', () {
    store.addFav(home);
    expect(calls, 1, reason: 'a home stop added');
    store.setLastBusNudge(false);
    expect(calls, 2);
    store.setLastBusNudge(true);
    expect(calls, 3, reason: 'on again: the alarm is set again');
  });

  test('without a home stop the setting changes nothing', () {
    store.setLastBusNudge(false);
    store.setLastBusNudge(true);
    expect(calls, 0);
  });

  test('other store changes do not touch the alarm', () {
    store.addFav(home);
    store.setLastBusNudge(true); // already on
    expect(calls, 1);
  });
}
