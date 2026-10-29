// «Γυρνάς σπίτι» on top of «Κοντά σου»: the next bus home there is time to walk to, and the last runs
// home today, the one that goes first on top. A tap plans the trip home; without a «Σπίτι» place the
// card asks for it.

import 'dart:async';

import 'package:flutter/material.dart';

import '../core/eta.dart';
import '../core/geo.dart';
import '../core/go_home.dart';
import '../core/leave.dart';
import '../core/models.dart';
import '../data/live.dart' show nextArrivalsAt;
import 'alert_sheet.dart' show dayClock;
import 'map_sel.dart';
import 'planner_screen.dart' show askHome;
import 'theme.dart';
import 'widgets.dart';

const _homeNearM = 500.0; // closer than this the user is home: no card
const _lastSoonS = 30 * 60; // the first last run within this: the warning colour

class GoHomeCard extends StatefulWidget {
  const GoHomeCard({super.key, required this.me, required this.ix});
  final Pt me;
  final TripIndex? ix;

  @override
  State<GoHomeCard> createState() => _GoHomeCardState();
}

class _GoHomeCardState extends State<GoHomeCard> {
  Object? _key; // what the ways home were found for: the position (to ~100 m), home and the index
  List<HomeBoard> _boards = [];
  List<HomeLast> _last = [];
  ({HomeBoard b, Arrival a, int leaveS})? _next;
  int _asked = 0; // the newest next-bus poll: an older, slower one must not overwrite it
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (_last.isEmpty) _loadLast(); // a timetable that failed (offline) is asked again
      _loadNext();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _refresh(Pt home) {
    final ix = widget.ix;
    if (ix == null) return;
    final key = ((widget.me.$1 * 1000).round(), (widget.me.$2 * 1000).round(), home, ix);
    if (key == _key) return;
    _key = key;
    _boards = homeBoards(ix, widget.me, home);
    _last = [];
    _next = null;
    _loadLast();
    _loadNext();
  }

  Future<void> _loadLast() async {
    final d = Deps.of(context);
    final boards = _boards;
    final lines = {for (final b in boards) b.line};
    try {
      await d.live.loadStatics(lines);
      final got = await Future.wait(lines.map(d.api.cachedSchedule));
      final sched = <String, Map<String, dynamic>>{
        for (final (k, l) in lines.indexed) l: ?got[k],
      };
      if (mounted && identical(boards, _boards)) setState(() => _last = lastHome(boards, sched, d.live.statics));
    } catch (_) {/* offline: the card shows the next bus only */}
  }

  // The first bus of any way home that the user can still walk to its stop for.
  Future<void> _loadNext() async {
    if (!mounted || _boards.isEmpty) return;
    final d = Deps.of(context);
    final boards = _boards;
    final n = ++_asked;
    try {
      await d.live.loadStatics({for (final b in boards) b.line});
      ({HomeBoard b, Arrival a, int leaveS})? best;
      for (final b in boards) {
        final walkS = walkMinutes(distM(widget.me, b.at)) * 60;
        for (final a in await nextArrivalsAt(d.live, b.line, b.variant, (b.stop, b.at.$1, b.at.$2))) {
          if (a.etaS < walkS) continue;
          if (best == null || a.etaS - walkS < best.leaveS) best = (b: b, a: a, leaveS: a.etaS - walkS);
          break;
        }
      }
      if (mounted && n == _asked && identical(boards, _boards)) setState(() => _next = best);
    } catch (_) {/* offline */}
  }

  @override
  Widget build(BuildContext context) {
    final d = Deps.of(context);
    final t = context.tones;
    final home = d.store.homePt;
    if (home == null) {
      return _shell(
        t,
        onTap: () => askHome(context),
        children: [
          _kicker('ΓΥΡΝΑΣ ΣΠΙΤΙ'),
          const SizedBox(height: 2),
          const Text('Πού είναι το σπίτι σου; ›', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
          _sub('Αρκεί μια περιοχή. Ανώνυμο: μένει μόνο στο κινητό.'),
        ],
      );
    }
    if (distM(widget.me, home) < _homeNearM) return const SizedBox.shrink();
    _refresh(home);
    final nowS = serviceNowS(DateTime.now().toUtc());
    final last = _last.where((x) => x.atS > nowS).take(3).toList();
    final soon = last.isNotEmpty && last.first.atS - nowS <= _lastSoonS;
    final n = _next;
    final head = n != null
        ? '${n.leaveS < 60 ? 'Φύγε τώρα' : 'Φύγε σε ${(n.leaveS / 60).floor()}′'} · ${n.b.line}'
        : _boards.isEmpty
            ? (widget.ix == null ? 'Ψάχνω…' : 'Χωρίς απευθείας λεωφορείο')
            : 'Με το ${_boards.first.line} από ${titleCase(_boards.first.stop)}';
    return _shell(
      t,
      onTap: () => showPlanner(from: (label: 'Η θέση μου', pts: [widget.me]), to: (label: 'Σπίτι', pts: [home])),
      children: [
        _kicker('ΓΥΡΝΑΣ ΣΠΙΤΙ'),
        const SizedBox(height: 2),
        Text(head, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white)),
        if (n != null) _sub('από ${titleCase(n.b.stop)} · περνά σε ${mins(n.a.etaS)}'),
        if (_boards.isEmpty && widget.ix != null) _sub('Πάτα για διαδρομή με αλλαγή ή μετρό.'),
        if (n == null && _boards.isNotEmpty) _sub('Δεν βλέπω λεωφορείο να έρχεται τώρα.'),
        if (last.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              '${last.length == 1 ? 'τελευταίο' : 'τελευταία'}: ${last.map((x) => '${x.line} στις ${dayClock(x.atS)}').join(' · ')}',
              style: TextStyle(fontSize: 12.5, fontWeight: soon ? FontWeight.w700 : FontWeight.w400, color: soon ? const Color(0xFFFFB38A) : Colors.white70),
            ),
          ),
      ],
    );
  }

  Widget _shell(Tones t, {required VoidCallback onTap, required List<Widget> children}) => Padding(
        padding: const EdgeInsets.only(top: 8, bottom: 4),
        child: Material(
          color: const Color(0xFF16181A),
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
            ),
          ),
        ),
      );

  Widget _kicker(String s) => Text(s, style: const TextStyle(fontSize: 11, letterSpacing: .3, color: Colors.white60));

  Widget _sub(String s) => Padding(
        padding: const EdgeInsets.only(top: 2),
        child: Text(s, style: const TextStyle(fontSize: 12.5, color: Colors.white70)),
      );
}
