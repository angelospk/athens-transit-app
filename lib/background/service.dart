// Alerts with the app closed. While a rule is active, an Android foreground service polls the rule's
// lines every 30 s, fires a notification per trip (RuleWatcher) and keeps an ongoing "live" notification
// with the bus's progress to the stop. A weekly rule's next start is an exact alarm that starts the
// service. No push server is needed: the phone does the watching (the bot's web push stays for the site).

import 'dart:convert';
import 'dart:io';

import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart' hide NotificationVisibility;
import 'package:shared_preferences/shared_preferences.dart';

import '../core/eta.dart';
import '../core/models.dart';
import '../core/rules.dart';
import '../data/api.dart';
import '../data/store.dart';

const _watcherKey = 'watcher_v1';
const _alarmId = 4242;
const _pollMs = 30000;
final _notes = FlutterLocalNotificationsPlugin();

const _hitChannel = AndroidNotificationDetails('hits', 'Το λεωφορείο έρχεται',
    channelDescription: 'Μία ειδοποίηση όταν το λεωφορείο φτάνει όσο νωρίς ζήτησες',
    importance: Importance.high, priority: Priority.high, category: AndroidNotificationCategory.reminder);

Future<void> _initNotes() => _notes.initialize(
      settings: const InitializationSettings(android: AndroidInitializationSettings('@mipmap/ic_launcher')),
    );

List<Rule> _rulesFrom(SharedPreferences p) {
  final raw = p.getString(stateKey);
  if (raw == null) return [];
  try {
    final j = jsonDecode(raw) as Map<String, dynamic>;
    return [for (final r in j['rules'] as List? ?? const []) Rule.fromJson(r as Map<String, dynamic>)];
  } catch (_) {
    return [];
  }
}

class AlertService {
  static Future<void> init(AppStore store) async {
    FlutterForegroundTask.initCommunicationPort();
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'live',
        channelName: 'Live πορεία λεωφορείου',
        channelDescription: 'Πού είναι το λεωφορείο σου ως τη στάση',
        onlyAlertOnce: true,
        visibility: NotificationVisibility.VISIBILITY_PUBLIC,
      ),
      iosNotificationOptions: const IOSNotificationOptions(showNotification: true, playSound: false),
      foregroundTaskOptions: ForegroundTaskOptions(eventAction: ForegroundTaskEventAction.repeat(_pollMs), allowWakeLock: true),
    );
    await _initNotes();
    if (Platform.isAndroid) await AndroidAlarmManager.initialize();
    await sync(store);
  }

  // Notifications (Android 13+), and exact alarms when a weekly rule needs them. false when
  // notifications are refused.
  static Future<bool> ensurePermissions(BuildContext context, {bool weekly = false}) async {
    var p = await FlutterForegroundTask.checkNotificationPermission();
    if (p != NotificationPermission.granted) p = await FlutterForegroundTask.requestNotificationPermission();
    final android = _notes.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (weekly && android != null && await android.canScheduleExactNotifications() == false) {
      await android.requestExactAlarmsPermission();
    }
    return p == NotificationPermission.granted;
  }

  // Exact alarms (Android 12+ special access; off by default for new installs on Android 14). Without
  // them a weekly rule still starts, through an inexact alarm that Android may delay by some minutes.
  static Future<bool> exactAllowed() async {
    if (!Platform.isAndroid) return true;
    final android = _notes.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    return await android?.canScheduleExactNotifications() ?? true;
  }

  static Future<void> askExact() async =>
      _notes.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()?.requestExactAlarmsPermission();

  // Start or stop the service for the rules active now, and set the alarm for the next weekly start.
  static Future<void> sync(AppStore store) async {
    final now = DateTime.now().toUtc();
    final active = store.rules.where((r) => r.activeAt(now)).toList();
    final running = await FlutterForegroundTask.isRunningService;
    if (active.isNotEmpty && !running) {
      await _start();
    } else if (active.isEmpty && running) {
      await FlutterForegroundTask.stopService();
    }
    await _scheduleNext(store.rules, now);
  }

  static Future<ServiceRequestResult> _start() => FlutterForegroundTask.startService(
        serviceId: 7,
        serviceTypes: [ForegroundServiceTypes.dataSync],
        notificationTitle: 'Athens Transit · live',
        notificationText: 'Παρακολουθώ τις γραμμές σου…',
        callback: startCallback,
      );

  static Future<void> _scheduleNext(List<Rule> rules, DateTime now) async {
    if (!Platform.isAndroid) return;
    await AndroidAlarmManager.cancel(_alarmId);
    DateTime? next;
    for (final r in rules) {
      final s = nextStartUtc(r, now);
      if (s != null && (next == null || s.isBefore(next))) next = s;
    }
    if (next == null) return;
    // Without the exact-alarm permission the plugin would skip an exact alarm silently: a late start
    // beats none.
    await AndroidAlarmManager.oneShotAt(next.toLocal(), _alarmId, alarmFired,
        exact: await exactAllowed(), wakeup: true, allowWhileIdle: true, rescheduleOnReboot: true);
  }
}

// A weekly rule starts: bring up the service. If Android refuses to start it from the background, a
// plain notification asks the user to open the app, which starts it.
@pragma('vm:entry-point')
Future<void> alarmFired() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final now = DateTime.now().toUtc();
  final rules = _rulesFrom(prefs);
  // The alarm is one-shot: set the next start now, so the rule keeps running with the app closed.
  await AndroidAlarmManager.initialize();
  await AlertService._scheduleNext(rules, now); // strictly after now: never this same start again
  if (!rules.any((r) => r.activeAt(now.add(const Duration(minutes: 1))))) return;
  FlutterForegroundTask.init(
    androidNotificationOptions: AndroidNotificationOptions(channelId: 'live', channelName: 'Live πορεία λεωφορείου', onlyAlertOnce: true),
    iosNotificationOptions: const IOSNotificationOptions(),
    foregroundTaskOptions: ForegroundTaskOptions(eventAction: ForegroundTaskEventAction.repeat(_pollMs), allowWakeLock: true),
  );
  final r = await AlertService._start();
  if (r is ServiceRequestFailure) {
    await _initNotes();
    await _notes.show(
      id: 1,
      title: 'Ξεκινά ο κανόνας σου',
      body: 'Άνοιξε την εφαρμογή για live ειδοποιήσεις.',
      notificationDetails: const NotificationDetails(android: _hitChannel),
    );
  }
}

@pragma('vm:entry-point')
void startCallback() => FlutterForegroundTask.setTaskHandler(RuleTask());

class RuleTask extends TaskHandler {
  final _api = Api();
  final _statics = <String, LineStatic>{};
  RuleWatcher _watcher = RuleWatcher();
  SharedPreferences? _prefs;
  bool _busy = false;

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    _prefs = await SharedPreferences.getInstance();
    await _initNotes();
    final saved = _prefs!.getString(_watcherKey);
    if (saved != null) _watcher = RuleWatcher.fromJson(jsonDecode(saved) as Map<String, dynamic>);
    await _tick();
  }

  @override
  void onRepeatEvent(DateTime timestamp) => _tick();

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {}

  @override
  void onNotificationPressed() => FlutterForegroundTask.launchApp();

  Future<void> _tick() async {
    if (_busy) return;
    _busy = true;
    try {
      final p = _prefs!;
      await p.reload(); // the app may have changed the rules
      final now = DateTime.now().toUtc();
      final nowS = now.millisecondsSinceEpoch ~/ 1000;
      final active = _rulesFrom(p).where((r) => r.activeAt(now)).toList();
      if (active.isEmpty) {
        await FlutterForegroundTask.stopService();
        return;
      }
      final lives = <String, LineLive>{};
      var offline = false;
      for (final line in {for (final r in active) r.line}.take(maxLines)) {
        try {
          _statics[line] ??= await _api.lineStatic(line);
          lives[line] = await _api.live(line);
        } catch (_) {
          offline = true;
          final saved = await _api.savedLive(line);
          if (saved != null) lives[line] = saved;
        }
      }
      for (final h in _watcher.check(active, _statics, lives, nowS)) {
        final r = active.firstWhere((x) => x.id == h.ruleId);
        await _notes.show(
          id: h.vehicleId.hashCode & 0x7fffffff,
          title: '${h.line} → ${r.stopName}',
          body: hitText(h, r.stopName),
          notificationDetails: const NotificationDetails(android: _hitChannel),
        );
      }
      await p.setString(_watcherKey, jsonEncode(_watcher.toJson()));
      await _updateLive(active.where((r) => r.live).toList(), lives, nowS, offline);
    } finally {
      _busy = false;
    }
  }

  // The ongoing notification: the nearest bus of the first live rule, as "2 στάσεις · 3′".
  Future<void> _updateLive(List<Rule> rules, Map<String, LineLive> lives, int nowS, bool offline) async {
    String title = 'Athens Transit · live', text = 'Κανένα λεωφορείο με GPS ακόμη.';
    for (final r in rules) {
      final st = _statics[r.line], live = lives[r.line];
      if (st == null || live == null) continue;
      final arr = arrivalsAt(r.stopId, {r.line: st}, {r.line: live}, nowS).where((a) => a.variant == r.variant).toList();
      if (arr.isEmpty) continue;
      final a = arr.first;
      final left = a.stopsLeft;
      final late = (a.delayS ?? 0) >= 90 ? ' · +${(a.delayS! / 60).round()}′' : ' · στην ώρα του';
      title = a.etaS < 45 ? '${r.line} · φτάνει τώρα στο ${r.stopName}' : '${r.line} · φτάνει στο ${r.stopName} σε ${offline ? '~' : ''}${(a.etaS / 60).round()}′';
      text = [if (left != null) left == 1 ? 'επόμενη στάση' : '$left στάσεις', if (offline) 'χωρίς σήμα, εκτίμηση' else late.substring(3)].join(' · ');
      break;
    }
    await FlutterForegroundTask.updateService(notificationTitle: title, notificationText: text);
  }
}
