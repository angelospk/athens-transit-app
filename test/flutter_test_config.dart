// Every test runs in Greek (the app's default), whatever the machine's language.
import 'dart:async';

import 'package:athens_transit/l10n/l10n.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  debugLocale = greek;
  await testMain();
}
