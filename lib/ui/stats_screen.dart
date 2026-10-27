// Network statistics: the newest full day (vehicles, speed, trips that ran, hours, slowest and fastest lines).

import 'package:flutter/material.dart';

import '../core/stats.dart';
import 'widgets.dart';
import 'theme.dart';

const _days = ['Δευτέρα', 'Τρίτη', 'Τετάρτη', 'Πέμπτη', 'Παρασκευή', 'Σάββατο', 'Κυριακή'];
const _months = ['Ιανουαρίου', 'Φεβρουαρίου', 'Μαρτίου', 'Απριλίου', 'Μαΐου', 'Ιουνίου', 'Ιουλίου', 'Αυγούστου', 'Σεπτεμβρίου', 'Οκτωβρίου', 'Νοεμβρίου', 'Δεκεμβρίου'];

String _date(String iso) {
  final d = DateTime.tryParse(iso);
  return d == null ? iso : '${_days[d.weekday - 1]} ${d.day} ${_months[d.month - 1]}';
}

String _kmh(double v) => v.toStringAsFixed(1).replaceAll('.', ',');

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  Future<DayStats>? _day;

  void _load() => setState(() => _day = Deps.of(context).api.stats());

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _day ??= Deps.of(context).api.stats();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tones;
    return Scaffold(
      appBar: AppBar(title: const Text('Στατιστικά δικτύου')),
      body: FutureBuilder<DayStats>(
        future: _day,
        builder: (context, snap) {
          if (snap.hasError) {
            return Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Text('Δεν φόρτωσαν τα στατιστικά.', style: TextStyle(color: t.muted)),
                const SizedBox(height: 8),
                OutlinedButton(onPressed: _load, child: const Text('Δοκίμασε ξανά')),
              ]),
            );
          }
          final d = snap.data;
          if (d == null) return const Center(child: CircularProgressIndicator());
          return _body(d, t);
        },
      ),
    );
  }

  Widget _body(DayStats d, Tones t) {
    final speed = d.kmh;
    final trips = tripShare(d);
    final r = ranking(d, 5);
    return ListView(padding: const EdgeInsets.fromLTRB(20, 12, 20, 24), children: [
      Text(_date(d.date), style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: 12),
      Row(children: [
        _tile(t, '${d.vehicles}', 'λεωφορεία'),
        const SizedBox(width: 8),
        _tile(t, '${d.lines}', 'γραμμές'),
        const SizedBox(width: 8),
        _tile(t, speed == null ? '–' : _kmh(speed), 'μέση χλμ/ώ'),
      ]),
      if (trips != null) ..._tripsSection(t, trips),
      _title('Λεωφορεία ανά ώρα'),
      _bars(t, d),
      if (r.slow.isNotEmpty) ...[_title('Πιο αργές γραμμές'), for (final x in r.slow) _rank(t, x)],
      if (r.fast.isNotEmpty) ...[_title('Πιο γρήγορες γραμμές'), for (final x in r.fast) _rank(t, x)],
      const SizedBox(height: 20),
      Text('Πηγή: καταγραφές θέσεων του ΟΑΣΑ από τον server μας. Ανανεώνεται μία φορά τη μέρα.',
          style: TextStyle(fontSize: 12, color: t.muted)),
    ]);
  }

  Widget _title(String s) => Padding(
        padding: const EdgeInsets.only(top: 22, bottom: 8),
        child: Text(s, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
      );

  Widget _tile(Tones t, String big, String label) => Expanded(
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: t.surface, borderRadius: BorderRadius.circular(12)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(big, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
            Text(label, style: TextStyle(fontSize: 12, color: t.muted)),
          ]),
        ),
      );

  List<Widget> _tripsSection(Tones t, TripShare s) => [
        _title('Δρομολόγια'),
        Text('Έγιναν ${(s.share * 100).round()}% των δρομολογίων', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        Text('${s.run} από ${s.measured}', style: TextStyle(color: t.muted)),
        if (s.expired)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text('Το πρόγραμμα του ΟΑΣΑ (GTFS) έχει λήξει: ${s.gtfs}. Μερικά δρομολόγια που λείπουν μπορεί να μην υπάρχουν πια.',
                style: TextStyle(fontSize: 13, color: t.late)),
          ),
        const SizedBox(height: 8),
        for (final w in s.worst)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(children: [
              LineBadge(w.line),
              const SizedBox(width: 12),
              Expanded(child: Text('${w.missed} από ${w.measured} δεν έγιναν')),
            ]),
          ),
        if (s.unseen > 0)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text('${s.unseen} γραμμές χωρίς κανένα δρομολόγιο', style: TextStyle(fontSize: 13, color: t.muted)),
          ),
      ];

  // Vehicles per hour 0-23, a bar each; the hour is labelled every 3 h.
  Widget _bars(Tones t, DayStats d) {
    final top = d.hours.fold(1, (m, h) => h.vehicles > m ? h.vehicles : m);
    return Column(children: [
      SizedBox(
        height: 110,
        child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          for (final h in d.hours)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 1),
                child: Container(
                  height: 2 + 108 * h.vehicles / top,
                  decoration: BoxDecoration(color: t.onTime, borderRadius: BorderRadius.circular(2)),
                ),
              ),
            ),
        ]),
      ),
      const SizedBox(height: 4),
      Row(children: [
        for (final h in d.hours)
          Expanded(
            child: Text(h.h % 3 == 0 ? '${h.h}' : '',
                textAlign: TextAlign.center, softWrap: false, overflow: TextOverflow.visible, style: TextStyle(fontSize: 11, color: t.muted)),
          ),
      ]),
    ]);
  }

  Widget _rank(Tones t, Ranked x) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(children: [
          LineBadge(x.line),
          const SizedBox(width: 12),
          Expanded(child: Text('${_kmh(x.kmh)} χλμ/ώ')),
          Text('${x.km} χλμ · ${x.hours} ώρες', style: TextStyle(fontSize: 12, color: t.muted)),
        ]),
      );
}
