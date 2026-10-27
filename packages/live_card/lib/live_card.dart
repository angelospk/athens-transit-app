// The bus's live card: an ongoing notification with the bus's progress to the stop. On Android 16 it
// asks to be a Live Update (the chip in the status bar and the top of the lock screen); elsewhere it is
// a normal ongoing notification with a progress bar. It replaces the notification with the same id, so
// it can stand in for a foreground service's notification.

import 'package:flutter/services.dart';

class LiveCard {
  static const _ch = MethodChannel('dev.haroldpoi/live_card');

  /// [progress] is 0..100, or negative for no bar. [chip] is the short status-bar text ("3′").
  static Future<void> show({
    required int id,
    required String title,
    required String text,
    String? sub,
    int progress = -1,
    String? chip,
    String endLabel = 'Τέλος',
  }) =>
      _ch.invokeMethod('show', {'id': id, 'title': title, 'text': text, 'sub': sub, 'progress': progress, 'chip': chip, 'endLabel': endLabel});

  /// true once after the user pressed the card's end button; the next call is false.
  static Future<bool> takeEnded() async => await _ch.invokeMethod<bool>('takeEnded') ?? false;
}
