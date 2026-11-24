// Network statistics. «Χθες»: the newest full day (vehicles, speed, trips that ran, hours, slowest and
// fastest lines). «Τάσεις»: the stored days together (speed by hour with its range, weekdays against
// weekends, the lines that changed most against their usual speed), as on the web page.

import 'package:flutter/material.dart';

import '../core/stats.dart';
import '../l10n/l10n.dart';
import 'map_sel.dart';
import 'widgets.dart';
import 'theme.dart';

const _days = ['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'];
const _months = ['jan', 'feb', 'mar', 'apr', 'may', 'jun', 'jul', 'aug', 'sep', 'oct', 'nov', 'dec'];

// «Δευτέρα 24 Νοεμβρίου», "Monday 24 November".
String _date(AppLocalizations l, String iso) {
  final d = DateTime.tryParse(iso);
  return d == null ? iso : l.statsDate(l.statsDayName(_days[d.weekday - 1]), d.day, l.statsMonthName(_months[d.month - 1]));
}

// «12,3» in Greek, "12.3" in English.
String _kmh(AppLocalizations l, double v) {
  final s = v.toStringAsFixed(1);
  return l.localeName == 'el' ? s.replaceAll('.', ',') : s;
}

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  Future<DayStats>? _day;
  Future<List<DayStats>>? _long;
  int _period = 7; // days for "Χειρότερες γραμμές"
  int _tab = 0; // «Τάσεις» when back from a line reopens the page

  void _load() => setState(() => _day = Deps.of(context).api.stats());
  void _loadLong() => setState(() => _long = Deps.of(context).api.storedDays());

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_day == null) {
      if (reopenedState(context) case final int p) {
        _period = p;
        _tab = 1;
      }
    }
    _day ??= Deps.of(context).api.stats();
    _long ??= Deps.of(context).api.storedDays();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tones;
    final l = context.l10n;
    return DefaultTabController(
      length: 2,
      initialIndex: _tab,
      child: Scaffold(
        appBar: AppBar(
          title: Text(l.statsTitle),
          bottom: TabBar(tabs: [Tab(text: l.statsTabYesterday), Tab(text: l.statsTabTrends)]),
        ),
        body: TabBarView(children: [_dayTab(t), _longTab(t)]),
      ),
    );
  }

  Widget _retry(Tones t, String msg, VoidCallback again) => Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(msg, style: TextStyle(color: t.muted)),
          const SizedBox(height: 8),
          OutlinedButton(onPressed: again, child: Text(context.l10n.commonRetry)),
        ]),
      );

  Widget _longTab(Tones t) => FutureBuilder<List<DayStats>>(
        future: _long,
        builder: (context, snap) {
          if (snap.hasError) return _retry(t, context.l10n.statsLongError, _loadLong);
          final all = snap.data;
          if (all == null) return const Center(child: CircularProgressIndicator());
          final days = [for (final d in all) if (complete(d)) d];
          if (days.length < 2) return Center(child: Text(context.l10n.statsNeedDays, style: TextStyle(color: t.muted)));
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
    final l = context.l10n;
    return ListView(padding: const EdgeInsets.fromLTRB(20, 12, 20, 24), children: [
      Text(l.statsLastDays(days.length), style: Theme.of(context).textTheme.titleLarge),
      Text('${_date(l, days.first.date)} – ${_date(l, days.last.date)}', style: TextStyle(color: t.muted)),
      _title(l.statsSpeedByHour),
      Text(l.statsSpeedNote, style: TextStyle(fontSize: 13, color: t.muted)),
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
      _title(l.statsWeekdaysWeekends),
      Row(children: [
        _tile(t, types.weekday.kmh == null ? '–' : _kmh(l, types.weekday.kmh!), l.statsKmhWeekdays(types.weekday.days)),
        const SizedBox(width: 8),
        _tile(t, types.weekend.kmh == null ? '–' : _kmh(l, types.weekend.kmh!), l.statsKmhWeekends(types.weekend.days)),
      ]),
      const SizedBox(height: 10),
      Text(l.statsBusesByHour, style: TextStyle(fontSize: 13, color: t.muted)),
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
        Text(l.statsLegendWeekday, style: TextStyle(fontSize: 12, color: t.muted)),
        const SizedBox(width: 12),
        Dot(t.late),
        const SizedBox(width: 4),
        Text(l.statsLegendWeekend, style: TextStyle(fontSize: 12, color: t.muted)),
      ]),
      ..._worst(t, days),
      if (trends != null) ...[
        _title(l.statsChanged(_date(l, trends.date))),
        Text(trends.weekend ? l.statsComparedWeekends(trends.baseDays) : l.statsComparedWeekdays(trends.baseDays), style: TextStyle(fontSize: 13, color: t.muted)),
        for (final x in trends.slower) _trend(t, x),
        for (final x in trends.faster) _trend(t, x),
      ],
      const SizedBox(height: 20),
      Text(l.statsLongSource,
          style: TextStyle(fontSize: 12, color: t.muted)),
    ]);
  }

  // The worst lines of the last _period complete days: missed trips, then the slowest. A tap opens the line.
  List<Widget> _worst(Tones t, List<DayStats> days) {
    final last = days.length <= _period ? days : days.sublist(days.length - _period);
    final w = worstOver(last);
    final l = context.l10n;
    Widget row(String line, String text, String note) => InkWell(
          onTap: () {
            keepPageState(context, _period); // back from the line reopens «Τάσεις» with this period
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
      _title(l.statsWorst),
      Wrap(spacing: 6, children: [
        for (final p in const [7, 14, 28])
          if (p == 7 || days.length > p ~/ 2)
            ChoiceChip(label: Text(l.statsDaysCount(p)), selected: _period == p, onSelected: (_) => setState(() => _period = p)),
      ]),
      Text('${_date(l, last.first.date)} – ${_date(l, last.last.date)} · ${l.statsDaysCount(last.length)}',
          style: TextStyle(fontSize: 13, color: t.muted)),
      const SizedBox(height: 8),
      Text(l.statsMissedTitle, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: t.muted)),
      if (w.missed.isEmpty) Text(l.statsNoLines, style: TextStyle(color: t.muted)),
      for (final x in w.missed) row(x.line, l.statsMissedOf(x.missed, x.measured), '${(100 * x.missed / x.measured).round()}%'),
      if (w.expiredDays > 0)
        Text(l.statsExpiredDays(w.expiredDays, last.length),
            style: TextStyle(fontSize: 12, color: t.late)),
      const SizedBox(height: 10),
      Text(l.statsSlowest, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: t.muted)),
      for (final x in w.slow) row(x.line, l.statsKmh(_kmh(l, x.kmh)), l.statsHours(x.hours)),
      const SizedBox(height: 4),
      Text(l.statsNoDelayNote,
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
          Expanded(child: Text(context.l10n.statsTrend(_kmh(context.l10n, x.kmh), _kmh(context.l10n, x.base)))),
          Text('${x.change > 0 ? '+' : '−'}${(x.change.abs() * 100).round()}%',
              style: TextStyle(fontWeight: FontWeight.w700, color: x.change < 0 ? t.late : t.onTime)),
        ]),
      );

  Widget _dayTab(Tones t) => FutureBuilder<DayStats>(
        future: _day,
        builder: (context, snap) {
          if (snap.hasError) return _retry(t, context.l10n.statsDayError, _load);
          final d = snap.data;
          if (d == null) return const Center(child: CircularProgressIndicator());
          return _body(d, t);
        },
      );

  Widget _body(DayStats d, Tones t) {
    final speed = d.kmh;
    final trips = tripShare(d);
    final r = ranking(d, 5);
    final l = context.l10n;
    return ListView(padding: const EdgeInsets.fromLTRB(20, 12, 20, 24), children: [
      Text(_date(l, d.date), style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: 12),
      Row(children: [
        _tile(t, '${d.vehicles}', l.statsBuses),
        const SizedBox(width: 8),
        _tile(t, '${d.lines}', l.statsLines),
        const SizedBox(width: 8),
        _tile(t, speed == null ? '–' : _kmh(l, speed), l.statsAvgKmh),
      ]),
      if (trips != null) ..._tripsSection(t, trips),
      _title(l.statsBusesByHour),
      _bars(t, d),
      if (r.slow.isNotEmpty) ...[_title(l.statsSlowLines), for (final x in r.slow) _rank(t, x)],
      if (r.fast.isNotEmpty) ...[_title(l.statsFastLines), for (final x in r.fast) _rank(t, x)],
      const SizedBox(height: 20),
      Text(l.statsDaySource,
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
        _title(context.l10n.statsTrips),
        Text(context.l10n.statsTripsShare((s.share * 100).round()), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        Text(context.l10n.statsRunOf(s.run, s.measured), style: TextStyle(color: t.muted)),
        if (s.expired)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(context.l10n.statsExpired(s.gtfs.split('-').reversed.join('/')),
                style: TextStyle(fontSize: 13, color: t.late)),
          ),
        const SizedBox(height: 8),
        for (final w in s.worst)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(children: [
              LineBadge(w.line),
              const SizedBox(width: 12),
              Expanded(child: Text(context.l10n.statsMissedOf(w.missed, w.measured))),
            ]),
          ),
        if (s.unseen > 0)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(context.l10n.statsUnseen(s.unseen), style: TextStyle(fontSize: 13, color: t.muted)),
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
          Expanded(child: Text(context.l10n.statsKmh(_kmh(context.l10n, x.kmh)))),
          Text(context.l10n.statsKmHours(x.km, x.hours), style: TextStyle(fontSize: 12, color: t.muted)),
        ]),
      );
}
