// The bus's live card: an ongoing notification with the bus's progress to the stop. On Android 16 it
// asks to be a Live Update (the chip in the status bar and the top of the lock screen); elsewhere it is
// a normal ongoing notification with a progress bar. It replaces the notification with the same id, so
// it can stand in for a foreground service's notification.

import 'package:flutter/services.dart';

class LiveCard {
  static const _ch = MethodChannel('dev.haroldpoi/live_card');

  /// [progress] is 0..100, or negative for no bar. [chip] is the short status-bar text ("3′"). The end
  /// button reports [ruleId] through [takeEnded]; a tap on the card opens the app with [open], which
  /// [takeOpen] returns.
  static Future<void> show({
    required int id,
    required String title,
    required String text,
    String? sub,
    int progress = -1,
    String? chip,
    String endLabel = 'Σταμάτα',
    String ruleId = '',
    String? open,
  }) =>
      _ch.invokeMethod('show', {
        'id': id, 'title': title, 'text': text, 'sub': sub, 'progress': progress, 'chip': chip, 'endLabel': endLabel,
        'ruleId': ruleId, 'open': open,
      });

  /// The rule ids whose card the user ended since the last call (each is returned once).
  static Future<List<String>> takeEnded() async => [...?await _ch.invokeListMethod<String>('takeEnded')];

  /// What the tapped card asked to open, once; null when the app was not opened from the card (or on a
  /// platform without the native side).
  static Future<String?> takeOpen() async {
    try {
      return await _ch.invokeMethod<String>('takeOpen');
    } on MissingPluginException {
      return null;
    }
  }

  /// A tap on the card while the app is already open (no launch, no resume): [f] gets its payload.
  static void onOpen(void Function(String) f) => _ch.setMethodCallHandler((c) async {
        if (c.method == 'open' && c.arguments is String) f(c.arguments as String);
      });
}
