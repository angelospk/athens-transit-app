// «Ακολούθησέ με» on a planned trip: a one-off rule for its first bus. The background service samples
// the phone (location while the app was in use is enough: the service starts from here) and the buses
// of that direction; once the phone rides one, it alerts one stop before the stop to get off at, as
// «Είμαι μέσα» does. It works with the app closed and the screen off.

import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:geolocator/geolocator.dart';

import '../background/service.dart';
import '../core/route_steps.dart';
import '../core/rules.dart';
import 'theme.dart';
import 'widgets.dart';

class FollowButton extends StatefulWidget {
  const FollowButton({super.key, required this.steps, required this.bus});
  final List<RouteStep> steps;
  final RouteStep bus; // the first bus of the trip

  @override
  State<FollowButton> createState() => _FollowButtonState();
}

class _FollowButtonState extends State<FollowButton> {
  bool _busy = false;
  String? _on; // the rule id once following

  Future<void> _follow() async {
    final d = Deps.of(context);
    final b = widget.bus;
    setState(() => _busy = true);
    try {
      var p = await Geolocator.checkPermission();
      if (p == LocationPermission.denied) p = await Geolocator.requestPermission();
      if (!mounted) return;
      if (p == LocationPermission.denied || p == LocationPermission.deniedForever || !await Geolocator.isLocationServiceEnabled()) {
        _say('Χρειάζομαι την τοποθεσία για να καταλάβω πότε ανεβαίνεις.');
        return;
      }
      if (!mounted) return;
      await AlertService.ensurePermissions(context);
      final st = d.live.statics[b.line!] ??= await d.api.lineStatic(b.line!);
      final stops = st.variants[b.variant!]?.stops;
      if (stops == null || b.j == null || b.j! >= stops.length) {
        _say('Δεν βρήκα τη στάση στη γραμμή.');
        return;
      }
      final now = DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000;
      final id = 'follow$now';
      d.store.putRule(Rule(
        id: id,
        line: b.line!,
        variant: b.variant!,
        stopIndex: b.j!,
        stopId: stops[b.j!],
        stopName: b.to,
        mode: AlertMode.stops,
        n: 1,
        days: 0,
        startMin: 0,
        endMin: 0,
        untilS: now + (totalMinutes(widget.steps) + 60) * 60, // the trip and an hour to spare
        live: true,
        kind: RuleKind.board,
      ));
      await AlertService.sync(d.store);
      // Android starts a location service only from the app in front: gone to the background
      // meanwhile, it refuses.
      if (!await FlutterForegroundTask.isRunningService) {
        d.store.removeRule(id);
        _say('Δεν ξεκίνησε η παρακολούθηση. Πάτα ξανά με την εφαρμογή ανοιχτή.');
        return;
      }
      if (mounted) setState(() => _on = id);
    } catch (_) {
      _say('Δεν φόρτωσε η γραμμή. Δοκίμασε ξανά με σύνδεση.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _stop() async {
    final d = Deps.of(context);
    final id = _on;
    if (id == null) return;
    d.store.removeRule(id);
    await AlertService.sync(d.store);
    if (mounted) setState(() => _on = null);
  }

  void _say(String s) {
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s)));
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tones;
    final b = widget.bus;
    if (_on != null) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: t.surface, borderRadius: BorderRadius.circular(16)),
        child: Row(children: [
          const Icon(Icons.my_location),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Σε ακολουθώ. Όταν ανέβεις στο ${b.line}, το καταλαβαίνω και σε ειδοποιώ μία στάση πριν από ${titleCase(b.to)}, και με κλειστή εφαρμογή.',
              style: const TextStyle(fontSize: 14, height: 1.35),
            ),
          ),
          TextButton(onPressed: _stop, child: const Text('Σταμάτα')),
        ]),
      );
    }
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: FilledButton.icon(
        icon: _busy ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.my_location),
        label: const Text('Ακολούθησέ με'),
        onPressed: _busy ? null : _follow,
      ),
    );
  }
}
