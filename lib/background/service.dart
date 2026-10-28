// Alerts with the app closed. While a rule is active, an Android foreground service polls the rule's
// lines as the contract allows (~30 s), fires a notification per trip (RuleWatcher) and keeps an ongoing
// "live" notification with the bus's progress to the stop, recounted every 10 s so it agrees with the
// app. "Σταμάτα" on that card stops the rule for today (a one-off rule for good). Tapping either
// notification opens the app on the bus, with the stop behind it. A weekly rule's next start is an exact alarm that starts the
// service. No push server is needed: the phone does the watching (the bot's web push stays for the site).

import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:live_card/live_card.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart' hide NotificationVisibility;
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/athens_time.dart';
import '../core/board.dart';
import '../core/geo.dart';
import '../core/last_bus.dart';
import '../core/eta.dart';
import '../core/models.dart';
import '../core/rules.dart';
import '../data/api.dart' hide Place;
import '../data/live.dart' show stopIdsNear;
import '../data/store.dart';
import '../ui/map_sel.dart' show appTab;
import '../ui/widgets.dart' show mins, titleCase;

const _watcherKey = 'watcher_v1';
const _alarmId = 4242;
const _nudgeAlarmId = 4343; // Friday and Saturday evening: «το τελευταίο προς το σπίτι»
const _noteAlarmBase = 5000; // notifications at a time (not a bus): alarm ids from here
const _notePrefix = 'timenote_v1.'; // + alarm id → {"title", "body", "payload"}
const _noteNextKey = 'timenote_next_v1'; // the next alarm id after _noteAlarmBase
const _favsPayload = 'tab:favs'; // a tap opens Αγαπημένα
const _tickMs = 10000; // the card is recounted this often; each line is polled when its data is due
const _serviceId = 7; // also the id of the service's notification, which the live card replaces
const _boardedPrefix = 'boarded_v1.'; // + rule id → the vehicle a followed trip («Ακολούθησέ με») rides
const _locationKey = 'service_location_v1'; // the running service may read the location
const _stoppedPrefix = 'stopped_v1.'; // + rule id → until (Unix s): stopped from the card ("Σταμάτα"). One key
// per rule, so the app (resume) and the service (stop) never overwrite each other's entries.
final _notes = FlutterLocalNotificationsPlugin();

const _hitChannel = AndroidNotificationDetails('hits', 'Το λεωφορείο έρχεται',
    channelDescription: 'Μία ειδοποίηση όταν το λεωφορείο φτάνει όσο νωρίς ζήτησες',
    importance: Importance.high, priority: Priority.high, category: AndroidNotificationCategory.reminder, icon: 'ic_stat_bus');

Future<void> _initNotes({void Function(String payload)? onOpen}) => _notes.initialize(
      settings: const InitializationSettings(android: AndroidInitializationSettings('@mipmap/ic_launcher')),
      onDidReceiveNotificationResponse: onOpen == null ? null : (r) => r.payload == null ? null : onOpen(r.payload!),
    );

// What a tapped notification opens: the bus on its way to the rule's stop.
// The bus's place and variant then: the map centres on it even outside the tiles it has loaded.
typedef OpenBus = ({String line, String vehicleId, String stop, double lat, double lon, double? busLat, double? busLon, String? variant});

String _openPayload(Rule r, String vehicleId, StopInfo? at, LineLive? live) {
  final v = live?.vehicles.where((x) => x.id == vehicleId).firstOrNull;
  return jsonEncode({
    'line': r.line, 'vehicle': vehicleId, 'stop': r.stopName, 'lat': at?.lat ?? 0, 'lon': at?.lon ?? 0,
    'busLat': v?.lat, 'busLon': v?.lon, 'variant': v?.variant ?? r.variant,
  });
}

OpenBus? parseOpen(String? payload) {
  if (payload == null || payload.isEmpty) return null;
  try {
    final j = jsonDecode(payload) as Map<String, dynamic>;
    return (
      line: j['line'] as String,
      vehicleId: j['vehicle'] as String,
      stop: j['stop'] as String,
      lat: (j['lat'] as num).toDouble(),
      lon: (j['lon'] as num).toDouble(),
      busLat: (j['busLat'] as num?)?.toDouble(),
      busLon: (j['busLon'] as num?)?.toDouble(),
      variant: j['variant'] as String?,
    );
  } catch (_) {
    return null;
  }
}

Set<String> _stopped(SharedPreferences p, int nowS) => stoppedIds([
      for (final k in p.getKeys())
        if (k.startsWith(_stoppedPrefix)) '${k.substring(_stoppedPrefix.length)}|${p.getInt(k)}',
    ], nowS);

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
  /// [onOpen] gets a tapped notification's bus: from the live card, from an alert, or the one that
  /// launched the app.
  static Future<void> init(AppStore store, {required void Function(OpenBus) onOpen}) async {
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
      foregroundTaskOptions: ForegroundTaskOptions(eventAction: ForegroundTaskEventAction.repeat(_tickMs), allowWakeLock: true),
    );
    void open(String? payload) {
      if (payload == _favsPayload) appTab.value = 1;
      if (parseOpen(payload) case final o?) onOpen(o);
    }

    await _initNotes(onOpen: open);
    LiveCard.onOpen(open); // a tap on the card while the app is in front
    if (Platform.isAndroid) await AndroidAlarmManager.initialize();
    final launch = await _notes.getNotificationAppLaunchDetails();
    if (launch?.didNotificationLaunchApp ?? false) open(launch!.notificationResponse?.payload);
    await takeOpen(onOpen);
    await sync(store);
    await syncNudge(store);
    // A home stop added or removed later moves the evening alarm too.
    var home = _hasHome(store);
    store.addListener(() {
      if (_hasHome(store) == home) return;
      home = !home;
      syncNudge(store);
    });
  }

  static bool _hasHome(AppStore store) => store.favs.any((f) => f.place == Place.home && f.lines.isNotEmpty);

  /// The live card's bus, when a tap on the card opened the app.
  static Future<void> takeOpen(void Function(OpenBus) onOpen) async {
    if (parseOpen(await LiveCard.takeOpen()) case final o?) onOpen(o);
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
    final p = await SharedPreferences.getInstance();
    await p.reload(); // the service may have stopped a rule
    final stopped = _stopped(p, now.millisecondsSinceEpoch ~/ 1000);
    final active = store.rules.where((r) => r.activeAt(now) && !stopped.contains(r.id)).toList();
    var running = await FlutterForegroundTask.isRunningService;
    // A followed trip reads the location in the service: Android lets a service of the location type
    // start only from the app in front, with the permission granted.
    final where = active.any((r) => r.kind == RuleKind.board) && await _canLocate();
    if (running && where && !(p.getBool(_locationKey) ?? false)) {
      await FlutterForegroundTask.stopService();
      running = false;
    }
    if (active.isNotEmpty && !running) {
      await _start(location: where);
    } else if (active.isEmpty && running) {
      await FlutterForegroundTask.stopService();
    }
    await _scheduleNext(store.rules, now);
  }

  /// Rule ids stopped from the live card until later today (the rules screen says so).
  static Future<Set<String>> stoppedNow() async {
    final p = await SharedPreferences.getInstance();
    await p.reload();
    return _stopped(p, DateTime.now().millisecondsSinceEpoch ~/ 1000);
  }

  /// Undo "Σταμάτα": the rule runs again today.
  static Future<void> resume(AppStore store, String ruleId) async {
    final p = await SharedPreferences.getInstance();
    await p.remove('$_stoppedPrefix$ruleId');
    await sync(store);
  }

  static Future<bool> _canLocate() async {
    final p = await Geolocator.checkPermission();
    return p == LocationPermission.whileInUse || p == LocationPermission.always;
  }

  static Future<ServiceRequestResult> _start({bool location = false}) async {
    (await SharedPreferences.getInstance()).setBool(_locationKey, location);
    return FlutterForegroundTask.startService(
      serviceId: _serviceId,
      serviceTypes: [ForegroundServiceTypes.dataSync, if (location) ForegroundServiceTypes.location],
      notificationTitle: 'Athens Transit · live',
      notificationText: 'Παρακολουθώ τις γραμμές σου…',
      callback: startCallback,
    );
  }

  /// A notification at [utc] (a time, not a bus): «σε 30′ φεύγει το τελευταίο». Kept by the alarm
  /// across a reboot; the text waits in the preferences.
  static Future<void> noteAt(DateTime utc, String title, String body, {String? payload}) async {
    if (!Platform.isAndroid) return;
    final p = await SharedPreferences.getInstance();
    final n = p.getInt(_noteNextKey) ?? 0; // two notes for one minute are two alarms
    await p.setInt(_noteNextKey, (n + 1) % 100000);
    final id = _noteAlarmBase + n;
    await p.setString('$_notePrefix$id', jsonEncode({'title': title, 'body': body, 'payload': payload}));
    await AndroidAlarmManager.oneShotAt(utc.toLocal(), id, noteFired,
        exact: await exactAllowed(), wakeup: true, allowWhileIdle: true, rescheduleOnReboot: true);
  }

  /// The evening suggestion: an alarm at the next Friday or Saturday 21:00 while there is a home stop
  /// and the setting is on.
  static Future<void> syncNudge(AppStore store) async {
    if (!Platform.isAndroid) return;
    await AndroidAlarmManager.cancel(_nudgeAlarmId);
    if (!store.lastBusNudge || !_hasHome(store)) return;
    await AndroidAlarmManager.oneShotAt(nextNudgeUtc(DateTime.now().toUtc()).toLocal(), _nudgeAlarmId, nudgeFired,
        exact: false, wakeup: false, allowWhileIdle: true, rescheduleOnReboot: true);
  }

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
    foregroundTaskOptions: ForegroundTaskOptions(eventAction: ForegroundTaskEventAction.repeat(_tickMs), allowWakeLock: true),
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
Future<void> noteFired(int id) async {
  WidgetsFlutterBinding.ensureInitialized();
  final p = await SharedPreferences.getInstance();
  await p.reload(); // the alarm isolate may live on with an old copy
  final raw = p.getString('$_notePrefix$id');
  if (raw == null) return;
  await p.remove('$_notePrefix$id');
  final j = jsonDecode(raw) as Map<String, dynamic>;
  await _initNotes();
  await _notes.show(
    id: id,
    title: j['title'] as String?,
    body: j['body'] as String?,
    notificationDetails: const NotificationDetails(android: _hitChannel),
    payload: j['payload'] as String?,
  );
}

// Friday or Saturday 21:00: when the last bus home leaves, from today's timetable when the network
// answers, and the next evening's alarm.
@pragma('vm:entry-point')
Future<void> nudgeFired() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AndroidAlarmManager.initialize();
  final prefs = await SharedPreferences.getInstance();
  await prefs.reload(); // the alarm isolate may live on with an old copy
  final store = AppStore(prefs);
  await AlertService.syncNudge(store);
  final home = store.favs.where((f) => f.place == Place.home && f.lines.isNotEmpty).firstOrNull;
  if (!store.lastBusNudge || home == null) return;
  var body = 'Δες πότε φεύγει το τελευταίο ${home.lines.first} για ${titleCase(home.name)} και βάλε ειδοποίηση.';
  try {
    final api = Api();
    final line = home.lines.first;
    final st = await api.lineStatic(line);
    final sched = await api.lineSchedule(line);
    final h = sched == null ? null : homeLast(sched, st, stopIdsNear(st, home.name, home.lat, home.lon));
    if (h != null) body = 'Το τελευταίο $line φεύγει ${gtfsClock(h.t)} από ${titleCase(h.from)}. Θες ειδοποίηση;';
  } catch (_) {/* the general text */}
  await _initNotes();
  await _notes.show(
    id: _nudgeAlarmId,
    title: 'Βράδυ ${athensWall(DateTime.now().toUtc()).weekday == DateTime.friday ? 'Παρασκευής' : 'Σαββάτου'} · το τελευταίο για το σπίτι',
    body: body,
    notificationDetails: const NotificationDetails(android: _hitChannel),
    payload: _favsPayload,
  );
}

@pragma('vm:entry-point')
void startCallback() => FlutterForegroundTask.setTaskHandler(RuleTask());

class RuleTask extends TaskHandler {
  final _api = Api();
  final _statics = <String, LineStatic>{};
  final _lives = <String, LineLive>{};
  final _due = <String, int>{}; // Unix s: when a line's next data is out (next_update_at + 2 s)
  final _offline = <String>{};
  RuleWatcher _watcher = RuleWatcher();
  final _startLeft = <String, int>{}; // stops left when the live card first showed a bus: the bar's 0 %
  final _boarding = <String, BoardWatch>{}; // followed trips still looking for their bus
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
      // "Σταμάτα" pressed on the card since the last tick: that rule stops until later today.
      final rules = _rulesFrom(p);
      final ended = await LiveCard.takeEnded();
      if (ended.isNotEmpty) {
        for (final r in rules) {
          if (ended.contains(r.id)) await p.setInt('$_stoppedPrefix${r.id}', stopUntilS(r, now));
        }
      }
      final stopped = _stopped(p, nowS);
      final all = rules.where((r) => r.activeAt(now) && !stopped.contains(r.id)).toList();
      if (all.isEmpty) {
        await FlutterForegroundTask.stopService();
        return;
      }
      // Followed trips: the bus each rides, once found; the keys of ended rules go.
      final ids = {for (final r in rules) r.id};
      for (final k in p.getKeys().where((k) => k.startsWith(_boardedPrefix)).toList()) {
        if (!ids.contains(k.substring(_boardedPrefix.length))) await p.remove(k);
      }
      final boarded = {
        for (final r in all) r.id: ?p.getString('$_boardedPrefix${r.id}'),
      };
      final looking = lookingRules(all, boarded);
      _boarding.removeWhere((id, _) => !looking.any((r) => r.id == id));
      final active = watchedRules(all, boarded);
      final lines = {for (final r in all) r.line}.take(maxLines).toSet();
      _lives.removeWhere((l, _) => !lines.contains(l));
      for (final line in lines) {
        if (nowS < (_due[line] ?? 0)) continue; // the backend has nothing newer yet
        try {
          _statics[line] ??= await _api.lineStatic(line);
          final l = _lives[line] = await _api.live(line);
          _offline.remove(line);
          final done = DateTime.now().millisecondsSinceEpoch ~/ 1000; // a slow answer must not shorten the gap
          _due[line] = max(l.nextUpdateAt + 2, done + 5);
        } catch (_) {
          _offline.add(line);
          _due[line] = DateTime.now().millisecondsSinceEpoch ~/ 1000 + 20;
          if (!_lives.containsKey(line)) {
            final saved = await _api.savedLive(line);
            if (saved != null) _lives[line] = saved;
          }
        }
      }
      final lives = {for (final l in lines) l: ?_lives[l]};
      final offline = lines.any(_offline.contains);
      await _look(p, looking, lives, nowS);
      for (final h in _watcher.check(active, _statics, lives, nowS)) {
        final r = active.firstWhere((x) => x.id == h.ruleId);
        // "Είμαι μέσα" is one ride: done once it fired, or the bus's next run would fire it again.
        if (r.kind == RuleKind.ride) await p.setInt('$_stoppedPrefix${r.id}', r.untilS ?? nowS + 3 * 3600);
        final (title, body) = ruleHitText(r, h, r.stopName);
        await _notes.show(
          id: (h.late ? 'late|${h.vehicleId}' : h.vehicleId).hashCode & 0x7fffffff, // the delay alert must not replace the arrival
          title: title,
          body: body,
          notificationDetails: const NotificationDetails(android: _hitChannel),
          payload: _openPayload(r, h.vehicleId, _statics[r.line]?.stops[r.stopId], lives[r.line]),
        );
      }
      await p.setString(_watcherKey, jsonEncode(_watcher.toJson()));
      await _updateLive(active.where((r) => r.live).toList(), lives, nowS, offline, looking: looking);
    } finally {
      _busy = false;
    }
  }

  // Followed trips: the phone now, and the buses of each trip's direction moved on to now. A bus the
  // phone rides becomes the trip's bus: the ride alert of that bus from the next tick.
  Future<void> _look(SharedPreferences p, List<Rule> looking, Map<String, LineLive> lives, int nowS) async {
    if (looking.isEmpty) return;
    Pt? me;
    try {
      final pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, timeLimit: Duration(seconds: 8)));
      me = (pos.latitude, pos.longitude);
    } catch (_) {
      return; // no fix this tick: the watch keeps what it has (a long gap starts it again)
    }
    for (final r in looking) {
      final buses = [
        for (final v in lives[r.line]?.vehicles ?? const <Vehicle>[])
          if (v.variant == r.variant && nowS - v.positionAt <= 180) v,
      ];
      final id = (_boarding[r.id] ??= BoardWatch()).add(nowS, me, buses);
      if (id == null) continue;
      _boarding.remove(r.id);
      await p.setString('$_boardedPrefix${r.id}', id);
      await _notes.show(
        id: 'board|${r.id}'.hashCode & 0x7fffffff,
        title: 'Είσαι στο ${r.line}',
        body: 'Θα σε ειδοποιήσω μία στάση πριν από ${titleCase(r.stopName)}.',
        notificationDetails: const NotificationDetails(android: _hitChannel),
      );
    }
  }

  // The live card: the nearest bus of the first live rule — "040 · Πανεπιστήμιο σε 3′", "φτάνει 8:56 ·
  // 2 στάσεις · στην ώρα του", and a bar from where it was when the card first showed it. The minutes
  // round as in the app (`mins`).
  Future<void> _updateLive(List<Rule> rules, Map<String, LineLive> lives, int nowS, bool offline, {List<Rule> looking = const []}) async {
    if (rules.isEmpty && looking.isNotEmpty) {
      final r = looking.first;
      await FlutterForegroundTask.updateService(
          notificationTitle: 'Σε ακολουθώ · ${r.line}', notificationText: 'Όταν ανέβεις, σε ειδοποιώ πριν από ${titleCase(r.stopName)}.');
      return;
    }
    if (rules.isEmpty) {
      await FlutterForegroundTask.updateService(notificationTitle: 'Athens Transit', notificationText: 'Σε ειδοποιώ όταν έρθει το λεωφορείο.');
      return;
    }
    String title = '${rules.first.line} · ${titleCase(rules.first.stopName)}', text = 'Κανένα λεωφορείο με GPS ακόμη.';
    var progress = -1;
    String? chip, open;
    var ruleId = rules.first.id;
    for (final r in rules) {
      final st = _statics[r.line], live = lives[r.line];
      if (st == null || live == null) continue;
      final arr = arrivalsAt(r.stopId, {r.line: st}, {r.line: live}, nowS)
          .where((a) => a.variant == r.variant && (r.vehicle == null || a.vehicleId == r.vehicle))
          .toList();
      if (arr.isEmpty) continue;
      final a = arr.first;
      final left = a.stopsLeft;
      final late = (a.delayS ?? 0) >= 90 ? '+${(a.delayS! / 60).round()}′' : 'στην ώρα του';
      final stop = titleCase(r.stopName);
      final at = athensWall(DateTime.fromMillisecondsSinceEpoch((nowS + a.etaS) * 1000, isUtc: true));
      final tilde = offline ? '~' : '';
      title = a.etaS < 45 ? '${r.line} · φτάνει τώρα στο $stop' : '${r.line} · $stop σε $tilde${mins(a.etaS)}';
      text = [
        if (a.etaS >= 45) 'φτάνει $tilde${at.hour}:${at.minute.toString().padLeft(2, '0')}',
        if (left != null) left == 1 ? 'επόμενη στάση' : '$left στάσεις',
        if (offline) 'χωρίς σήμα, εκτίμηση' else late,
      ].join(' · ');
      chip = mins(a.etaS);
      ruleId = r.id;
      open = _openPayload(r, a.vehicleId, st.stops[r.stopId], live);
      if (left != null) {
        final start = _startLeft[a.vehicleId] ??= left + 1;
        progress = (100 * (start - left) / start).round();
      }
      break;
    }
    await LiveCard.show(
        id: _serviceId, title: title, text: text, sub: offline ? 'χωρίς σήμα' : 'live', progress: progress, chip: chip, ruleId: ruleId, open: open);
  }
}
