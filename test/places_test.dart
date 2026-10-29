import 'dart:convert';

import 'package:athens_transit/data/store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('«Μέρη»: any number of places; one name is one place; they survive a restart', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final s = AppStore(prefs);
    s.putPlace(const SavedPlace(name: workName, label: 'Μαρούσι', lat: 38.05, lon: 23.8));
    s.putPlace(const SavedPlace(name: 'Γυμναστήριο', label: 'Παγκράτι', lat: 37.97, lon: 23.75));
    s.putPlace(const SavedPlace(name: workName, label: 'Χαλάνδρι', lat: 38.02, lon: 23.8));
    final back = AppStore(prefs);
    expect(back.places.map((p) => (p.name, p.label)), [(workName, 'Χαλάνδρι'), ('Γυμναστήριο', 'Παγκράτι')]);
    expect(back.work!.label, 'Χαλάνδρι');
    expect(back.workPt, (38.02, 23.8));
    back.removePlace('Γυμναστήριο');
    expect(AppStore(prefs).places.map((p) => p.name), [workName]);
  });

  test('«Σπίτι» is the place named Σπίτι; setHome keeps working', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final s = AppStore(prefs);
    s.setHome(const SavedPlace(label: 'Παγκράτι', lat: 37.968, lon: 23.744));
    expect(s.placeNamed(homeName)!.label, 'Παγκράτι');
    expect(s.places.length, 1);
    s.setHome(null);
    expect(AppStore(prefs).places, isEmpty);
  });

  test('a saved home from before «Μέρη» becomes the place «Σπίτι»', () async {
    SharedPreferences.setMockInitialValues({
      stateKey: jsonEncode({
        'home': {'label': 'Παγκράτι', 'lat': 37.968, 'lon': 23.744, 'approx': true},
      }),
    });
    final s = AppStore(await SharedPreferences.getInstance());
    expect((s.home!.name, s.home!.label, s.home!.approx), (homeName, 'Παγκράτι', true));
    expect(s.toJson().containsKey('home'), isFalse);
    expect((s.toJson()['places'] as List).length, 1);
  });

  test('without a «Δουλειά» place, the stop marked Δουλειά stands in for it', () async {
    SharedPreferences.setMockInitialValues({});
    final s = AppStore(await SharedPreferences.getInstance());
    expect(s.workPt, isNull);
    s.addFav(const FavStop(name: 'ΑΓ. ΘΩΜΑΣ', lat: 37.99, lon: 23.76, place: Place.work, lines: ['550']));
    expect(s.workPt, (37.99, 23.76));
  });
}
