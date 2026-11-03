import 'package:athens_transit/ui/menu.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Home-screen widgets exist only on Android: on iOS the menu has no «Widgets» page.
  for (final (platform, shown) in [(TargetPlatform.android, true), (TargetPlatform.iOS, false)]) {
    testWidgets('«Widgets» in the menu on ${platform.name}: $shown', (tester) async {
      debugDefaultTargetPlatformOverride = platform;
      await tester.pumpWidget(const MaterialApp(home: Scaffold(body: AppMenu())));
      expect(find.text('Widgets'), shown ? findsOneWidget : findsNothing);
      expect(find.text('Ρυθμίσεις'), findsOneWidget);
      debugDefaultTargetPlatformOverride = null;
    });
  }
}
