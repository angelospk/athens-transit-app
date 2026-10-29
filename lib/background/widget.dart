// Screen 11 · Widget "Η στάση μου": the first saved stop for this time of day (home in the morning,
// work after 15:00) and its lines' next arrivals, saved as clock times. The native widget
// (StopWidgetProvider.kt) redraws once a minute for the next half hour and counts down by itself.

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';

import '../core/go_home.dart';
import '../data/live.dart';
import '../data/store.dart';
import '../ui/theme.dart';
import '../ui/widgets.dart';

const _provider = 'StopWidgetProvider';
int _lastPush = 0;

Future<void> pushWidget(AppStore store, LiveHub live, {bool force = false}) async {
  final now = live.nowS;
  if (!force && now - _lastPush < 60) return;
  _lastPush = now;
  try {
    final favs = store.favsByTime(DateTime.now().toUtc());
    if (favs.isEmpty) {
      // Back to the layout's own text.
      for (final k in ['w_title', 'w_sub', 'w_rows', 'w_at']) {
        await HomeWidget.saveWidgetData<String>(k, null);
      }
      await HomeWidget.updateWidget(androidName: _provider);
      return;
    }
    final f = favs.first;
    final groups = groupArrivals(live.arrivalsNear(f.name, f.lat, f.lon, only: f.lines));
    final rows = [
      for (final (first, then) in groups)
        {
          'line': first.line,
          'bg': hex(lineColor(store, first.line).bg),
          'fg': hex(lineColor(store, first.line).fg),
          'note': '→ ${titleCase(first.headsign)}',
          'at': [for (final a in [first, ...then].take(3)) now + a.etaS],
        }
    ];
    final place = switch (f.place) { Place.home => 'Σπίτι', Place.work => 'Δουλειά', null => 'Η στάση μου' };
    await HomeWidget.saveWidgetData('w_title', titleCase(f.name));
    await HomeWidget.saveWidgetData('w_sub', rows.isEmpty ? '$place · κανένα λεωφορείο με GPS' : place);
    await HomeWidget.saveWidgetData('w_rows', jsonEncode(rows));
    await HomeWidget.saveWidgetData('w_at', now);
    await HomeWidget.updateWidget(androidName: _provider);
    await HomeWidget.scheduleWidgetUpdates(
      [for (var m = 1; m <= 30; m++) DateTime.now().add(Duration(minutes: m))],
      androidName: _provider,
    );
  } catch (e) {
    debugPrint('widget: $e'); // no widget on the home screen, or iOS without the extension
  }
}

const _homeProvider = 'HomeLastWidgetProvider';

/// Widget «Γυρνάς σπίτι»: today's last runs home from where the app last was (no location in the
/// background), the one that goes first on top, as clock times; the widget strikes the ones gone.
Future<void> pushHomeWidget(AppStore store, List<HomeLast> last, {required String from}) async {
  try {
    final now = DateTime.now().toUtc();
    await HomeWidget.saveWidgetData('h_from', titleCase(from));
    await HomeWidget.saveWidgetData('h_at', now.millisecondsSinceEpoch ~/ 1000);
    await HomeWidget.saveWidgetData(
      'h_rows',
      jsonEncode([
        for (final x in last.take(4))
          {
            'line': x.line,
            'bg': hex(lineColor(store, x.line).bg),
            'fg': hex(lineColor(store, x.line).fg),
            't': serviceMoment(x.atS, now).millisecondsSinceEpoch ~/ 1000,
          }
      ]),
    );
    await HomeWidget.updateWidget(androidName: _homeProvider);
    // «σε 18′» and the struck runs move on without the app: a redraw every 5′ for 2 hours.
    await HomeWidget.scheduleWidgetUpdates(
      [for (var m = 5; m <= 120; m += 5) DateTime.now().add(Duration(minutes: m))],
      androidName: _homeProvider,
    );
  } catch (e) {
    debugPrint('home widget: $e');
  }
}
