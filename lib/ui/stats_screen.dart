// Network statistics. «Χθες»: the newest full day (vehicles, speed, trips that ran, hours, slowest and
// fastest lines). «Τάσεις»: the stored days together (speed by hour with its range, weekdays against
// weekends, the lines that changed most against their usual speed), as on the web page.

import 'package:flutter/material.dart';

import '../core/stats.dart';
import 'map_sel.dart';
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
  Future<List<DayStats>>? _long;
  int _period = 7; // days for "Χειρότερες γραμμές"

  void _load() => setState(() => _day = Deps.of(context).api.stats());
  void _loadLong() => setState(() => _long = Deps.of(context).api.storedDays());

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _day ??= Deps.of(context).api.stats();
    _long ??= Deps.of(context).api.storedDays();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tones;
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Στατιστικά δικτύου'),
          bottom: const TabBar(tabs: [Tab(text: 'Χθες'), Tab(text: 'Τάσεις')]),
        ),
        body: TabBarView(children: [_dayTab(t), _longTab(t)]),
      ),
    );
  }

  Widget _retry(Tones t, String msg, VoidCallback again) => Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(msg, style: TextStyle(color: t.muted)),
          const SizedBox(height: 8),
          OutlinedButton(onPressed: again, child: const Text('Δοκίμασε ξανά')),
        ]),
      );

  Widget _longTab(Tones t) => FutureBuilder<List<DayStats>>(
        future: _long,
        builder: (context, snap) {
          if (snap.hasError) return _retry(t, 'Δεν φόρτωσαν οι προηγούμενες μέρες.', _loadLong);
          final all = snap.data;
          if (all == null) return const Center(child: CircularProgressIndicator());
          final days = [for (final d in all) if (complete(d)) d];
          if (days.length < 2) return Center(child: Text('Χρειάζονται τουλάχιστον 2 πλήρεις μέρες.', style: TextStyle(color: t.muted)));
          return _long$(t, days);
        },
      );

  // Speed by hour (pooled line, the range of the days around it), weekday/weekend, and the trends.
  Widget _long$(Tones t, List<DayStats> days) {
    final band = hourBand(days);
    final types = byDayType(days);
    final trends = lineTrends(days, 5);
    final top = band.fold(10.0, (m, b) => (b.max ?? 0) > m ? b.max! : m);
    final vTop = [...types.weekday.hours, ...types.weekend.hours].fold(1.0, (m, h) => (h.vehicles ?? 0) > m ? h.vehicles! : m);
    const h = 120.0;
    return ListView(padding: const EdgeInsets.fromLTRB(20, 12, 20, 24), children: [
      Text('Οι τελευταίες ${days.length} πλήρεις μέρες', style: Theme.of(context).textTheme.titleLarge),
      Text('${_date(days.first.date)} – ${_date(days.last.date)}', style: TextStyle(color: t.muted)),
      _title('Μέση ταχύτητα ανά ώρα'),
      Text('Η μπάρα: από την πιο αργή ως την πιο γρήγορη μέρα. Η τελεία: όλες μαζί.', style: TextStyle(fontSize: 13, color: t.muted)),
      const SizedBox(height: 8),
      SizedBox(
        height: h,
        child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          for (final b in band)
            Expanded(
              child: b.kmh == null
                  ? const SizedBox()
                  : Stack(alignment: Alignment.bottomCenter, children: [
                      Positioned(
                        bottom: h * (b.min ?? 0) / top,
                        height: (h * ((b.max ?? 0) - (b.min ?? 0)) / top).clamp(2, h),
                        width: 6,
                        child: DecoratedBox(decoration: BoxDecoration(color: t.indicator, borderRadius: BorderRadius.circular(3))),
                      ),
                      Positioned(
                        bottom: h * b.kmh! / top - 3,
                        child: Container(width: 6, height: 6, decoration: BoxDecoration(color: t.ink, shape: BoxShape.circle)),
                      ),
                    ]),
            ),
        ]),
      ),
      _hours(t),
      _title('Καθημερινές και Σαββατοκύριακα'),
      Row(children: [
        _tile(t, types.weekday.kmh == null ? '–' : _kmh(types.weekday.kmh!), 'χλμ/ώ καθημερινές (${types.weekday.days})'),
        const SizedBox(width: 8),
        _tile(t, types.weekend.kmh == null ? '–' : _kmh(types.weekend.kmh!), 'χλμ/ώ Σαβ/κο (${types.weekend.days})'),
      ]),
      const SizedBox(height: 10),
      Text('Λεωφορεία ανά ώρα', style: TextStyle(fontSize: 13, color: t.muted)),
      const SizedBox(height: 6),
      SizedBox(
        height: 90,
        child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          for (var i = 0; i < 24; i++)
            Expanded(
              child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Expanded(child: Container(height: 1 + 88 * (types.weekday.hours[i].vehicles ?? 0) / vTop, color: t.onTime)),
                Expanded(child: Container(height: 1 + 88 * (types.weekend.hours[i].vehicles ?? 0) / vTop, color: t.late)),
              ]),
            ),
        ]),
      ),
      _hours(t),
      const SizedBox(height: 6),
      Row(children: [
        Dot(t.onTime),
        const SizedBox(width: 4),
        Text('καθημερινή', style: TextStyle(fontSize: 12, color: t.muted)),
        const SizedBox(width: 12),
        Dot(t.late),
        const SizedBox(width: 4),
        Text('Σαββατοκύριακο', style: TextStyle(fontSize: 12, color: t.muted)),
      ]),
      ..._worst(t, days),
      if (trends != null) ...[
        _title('Γραμμές που άλλαξαν (${_date(trends.date)})'),
        Text('Σε σχέση με ${trends.baseDays} προηγούμενες ${trends.weekend ? 'μέρες Σαββατοκύριακου' : 'καθημερινές'}.', style: TextStyle(fontSize: 13, color: t.muted)),
        for (final x in trends.slower) _trend(t, x),
        for (final x in trends.faster) _trend(t, x),
      ],
      const SizedBox(height: 20),
      Text('Μόνο πλήρεις μέρες (χωρίς κενά στις καταγραφές). Πηγή: καταγραφές θέσεων του ΟΑΣΑ από τον server μας.',
          style: TextStyle(fontSize: 12, color: t.muted)),
    ]);
  }

  // The worst lines of the last _period complete days: missed trips, then the slowest. A tap opens the line.
  List<Widget> _worst(Tones t, List<DayStats> days) {
    final last = days.length <= _period ? days : days.sublist(days.length - _period);
    final w = worstOver(last);
    Widget row(String line, String text, String note) => InkWell(
          onTap: () {
            Navigator.of(context).popUntil((r) => r.isFirst); // stats is a pushed page over the tabs
            showOnMap(LineSel(line));
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(children: [
              LineBadge(line),
              const SizedBox(width: 12),
              Expanded(child: Text(text)),
              Text(note, style: TextStyle(fontSize: 12, color: t.muted)),
            ]),
          ),
        );
    return [
      _title('Χειρότερες γραμμές'),
      Wrap(spacing: 6, children: [
        for (final p in const [7, 14, 28])
          if (p == 7 || days.length > p ~/ 2)
            ChoiceChip(label: Text('$p μέρες'), selected: _period == p, onSelected: (_) => setState(() => _period = p)),
      ]),
      Text('${_date(last.first.date)} – ${_date(last.last.date)} · ${last.length} ${last.length == 1 ? 'μέρα' : 'μέρες'}',
          style: TextStyle(fontSize: 13, color: t.muted)),
      const SizedBox(height: 8),
      Text('Δρομολόγια που δεν έγιναν', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: t.muted)),
      if (w.missed.isEmpty) Text('Καμία γραμμή με αρκετά δρομολόγια.', style: TextStyle(color: t.muted)),
      for (final x in w.missed) row(x.line, '${x.missed} από ${x.measured} δεν έγιναν', '${(100 * x.missed / x.measured).round()}%'),
      if (w.expiredDays > 0)
        Text('${w.expiredDays} από τις ${last.length} μέρες μετρήθηκαν με ληγμένο πρόγραμμα (GTFS): κάποια «χαμένα» μπορεί να μην υπάρχουν πια.',
            style: TextStyle(fontSize: 12, color: t.late)),
      const SizedBox(height: 10),
      Text('Πιο αργές', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: t.muted)),
      for (final x in w.slow) row(x.line, '${_kmh(x.kmh)} χλμ/ώ', '${x.hours} ώρες'),
      const SizedBox(height: 4),
      Text('Καθυστέρηση ανά δρομολόγιο δεν καταγράφεται ακόμη· εδώ μετράνε τα χαμένα δρομολόγια και η ταχύτητα.',
          style: TextStyle(fontSize: 12, color: t.muted)),
    ];
  }

  Widget _hours(Tones t) => Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Row(children: [
          for (var i = 0; i < 24; i++)
            Expanded(child: Text(i % 3 == 0 ? '$i' : '', textAlign: TextAlign.center, softWrap: false, overflow: TextOverflow.visible, style: TextStyle(fontSize: 11, color: t.muted))),
        ]),
      );

  Widget _trend(Tones t, Trend x) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(children: [
          LineBadge(x.line),
          const SizedBox(width: 12),
          Expanded(child: Text('${_kmh(x.kmh)} χλμ/ώ (συνήθως ${_kmh(x.base)})')),
          Text('${x.change > 0 ? '+' : '−'}${(x.change.abs() * 100).round()}%',
              style: TextStyle(fontWeight: FontWeight.w700, color: x.change < 0 ? t.late : t.onTime)),
        ]),
      );

  Widget _dayTab(Tones t) => FutureBuilder<DayStats>(
        future: _day,
        builder: (context, snap) {
          if (snap.hasError) return _retry(t, 'Δεν φόρτωσαν τα στατιστικά.', _load);
          final d = snap.data;
          if (d == null) return const Center(child: CircularProgressIndicator());
          return _body(d, t);
        },
      );

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
