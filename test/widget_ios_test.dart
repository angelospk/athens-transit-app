import 'package:athens_transit/background/widget.dart';
import 'package:athens_transit/data/api.dart';
import 'package:athens_transit/data/live.dart';
import 'package:athens_transit/data/store.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Home-screen widgets exist only on Android: iOS has no app group for them, and each call failed.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final (platform, calls) in [(TargetPlatform.android, true), (TargetPlatform.iOS, false)]) {
    test('widget pushes on ${platform.name}: $calls', () async {
      final seen = <String>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
          const MethodChannel('home_widget'), (c) async {
        seen.add(c.method);
        return true;
      });
      SharedPreferences.setMockInitialValues({});
      final store = AppStore(await SharedPreferences.getInstance());
      debugDefaultTargetPlatformOverride = platform;
      await pushWidget(store, LiveHub(Api()), force: true);
      await clearHomeWidget();
      await pushHomeWidget(store, const [], from: 'ΣΤΑΣΗ');
      debugDefaultTargetPlatformOverride = null;
      expect(seen.isNotEmpty, calls);
    });
  }
}
