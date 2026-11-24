// The app's languages: Greek (the template and the default) and English. The app follows the device:
// the first of the phone's preferred languages that the app has wins; none of them: Greek.
//
// In a widget: `context.l10n`. Outside the widget tree (the background service, notifications, the
// home-screen widgets, core code that builds text): `l10n`, resolved from the device's languages.

import 'dart:ui' show Locale, PlatformDispatcher;

import 'package:flutter/widgets.dart';

import 'app_localizations.dart';

export 'app_localizations.dart';

const greek = Locale('el'), english = Locale('en');

/// The app's language for the device's preferred [locales], in order; Greek when none is known.
Locale resolveLocale(Iterable<Locale>? locales) {
  for (final l in locales ?? const <Locale>[]) {
    if (l.languageCode == 'el') return greek;
    if (l.languageCode == 'en') return english;
  }
  return greek;
}

/// For tests and previews: a fixed language instead of the device's.
Locale? debugLocale;

/// The device's language as the app uses it (also in a background isolate, which has no widget tree).
Locale get deviceLocale => debugLocale ?? resolveLocale(PlatformDispatcher.instance.locales);

AppLocalizations? _cached;

/// The texts in the device's language, for code outside the widget tree.
AppLocalizations get l10n => _device();

AppLocalizations _device() {
  final want = deviceLocale;
  final c = _cached;
  if (c != null && c.localeName == want.languageCode) return c;
  return _cached = lookupAppLocalizations(want);
}

extension L10nContext on BuildContext {
  /// The texts in the app's language, for a widget.
  /// Outside a MaterialApp that has the delegates (a bare test harness): the device's.
  AppLocalizations get l10n => Localizations.of<AppLocalizations>(this, AppLocalizations) ?? _device();
}
