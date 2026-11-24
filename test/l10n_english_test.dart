// The app follows the device: English on an English phone, Greek otherwise (resolveLocale), and the
// screens read their texts from the ARB files in either language.
import 'package:athens_transit/l10n/l10n.dart';
import 'package:athens_transit/ui/theme.dart';
import 'package:athens_transit/ui/welcome.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('the device language decides; any other language falls back to Greek', () {
    expect(resolveLocale(const [Locale('en', 'GB')]), english);
    expect(resolveLocale(const [Locale('el', 'GR')]), greek);
    expect(resolveLocale(const [Locale('de'), Locale('en')]), english, reason: 'the first one the app has');
    expect(resolveLocale(const [Locale('de'), Locale('fr')]), greek);
    expect(resolveLocale(const []), greek);
    expect(resolveLocale(null), greek);
  });

  test('outside the widget tree (notifications, the background service) the texts follow the device', () {
    addTearDown(() => debugLocale = greek);
    debugLocale = english;
    expect(l10n.appName, 'Staseis');
    expect(l10n.commonNow, 'now');
    debugLocale = greek;
    expect(l10n.appName, 'Στάσεις');
  });

  testWidgets('the welcome in English', (t) async {
    addTearDown(() => debugLocale = greek);
    debugLocale = english;
    await t.pumpWidget(MaterialApp(
      theme: buildTheme(Brightness.light),
      locale: english,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: WelcomeScreen(onDone: () {}, askLocation: () async => true, askNotifications: () async => true),
    ));
    await t.pumpAndSettle();
    expect(find.textContaining('Staseis'), findsWidgets);
    expect(find.textContaining(RegExp('[α-ωΑ-Ω]')), findsNothing, reason: 'no Greek left on the first card');
  });
}
