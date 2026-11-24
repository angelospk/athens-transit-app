// A line's speeds, from the bus sheet's "συνήθως": the bus now against the typical speed of the road
// ahead (path_speeds, from the backend's history), and the line's mean speed day by day (the daily
// statistics of the last 28 days), weekdays and weekends apart, and its place among all lines.

import 'package:flutter/material.dart';

import '../core/models.dart';
import '../core/stats.dart';
import '../l10n/l10n.dart';
import 'theme.dart';
import 'widgets.dart';

List<String> get _days => [l10n.lineSpeedMon, l10n.lineSpeedTue, l10n.lineSpeedWed, l10n.lineSpeedThu, l10n.lineSpeedFri, l10n.lineSpeedSat, l10n.lineSpeedSun];

// The decimal comma in Greek, the point in English.
String _dec(double v) => l10n.localeName == 'el' ? v.toStringAsFixed(1).replaceAll('.', ',') : v.toStringAsFixed(1);

Future<void> showLineSpeed(BuildContext context, {required String line, Vehicle? vehicle}) => showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (c) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: .7,
        maxChildSize: .92,
        builder: (c, scroll) => _LineSpeed(line: line, vehicle: vehicle, scroll: scroll),
      ),
    );

class _LineSpeed extends StatefulWidget {
  const _LineSpeed({required this.line, required this.vehicle, required this.scroll});
  final String line;
  final Vehicle? vehicle;
  final ScrollController scroll;

  @override
  State<_LineSpeed> createState() => _LineSpeedState();
}

class _LineSpeedState extends State<_LineSpeed> {
  Future<List<DayStats>>? _days$;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _days$ ??= Deps.of(context).api.storedDays();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tones;
    final v = widget.vehicle;
    return ListView(controller: widget.scroll, padding: const EdgeInsets.fromLTRB(20, 0, 20, 24), children: [
      Row(children: [
        LineBadge(widget.line, big: true),
        const SizedBox(width: 12),
        Expanded(child: Text(context.l10n.lineSpeedTitle, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600))),
      ]),
      if (v != null) ..._ahead(t, v),
      FutureBuilder<List<DayStats>>(
        future: _days$,
        builder: (context, snap) {
          if (snap.hasError) return Padding(padding: const EdgeInsets.only(top: 20), child: Text(context.l10n.lineSpeedDaysFailed, style: TextStyle(color: t.muted)));
          final days = snap.data;
          if (days == null) return const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator()));
          return _history(t, days);
        },
      ),
    ]);
  }

  // The typical speed of the next 2 km, 200 m a bar, with the bus's speed now as a line across.
  List<Widget> _ahead(Tones t, Vehicle v) {
    final steps = (v.pathSpeeds ?? const <double?>[]).take(10).toList();
    if (steps.isEmpty) return const [];
    final now = (v.speed ?? 0) * 3.6;
    final top = [now, for (final s in steps) (s ?? 0) * 3.6].fold(10.0, (m, x) => x > m ? x : m);
    const h = 90.0;
    return [
      const SizedBox(height: 16),
      Text(context.l10n.lineSpeedNext2km, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
      Text(context.l10n.lineSpeedAheadHint(now.round()),
          style: TextStyle(fontSize: 13, color: t.muted)),
      const SizedBox(height: 8),
      SizedBox(
        height: h + 18,
        child: Stack(children: [
          Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            for (final s in steps)
              Expanded(
                child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                  Text(s == null ? '–' : '${(s * 3.6).round()}', style: TextStyle(fontSize: 11, color: t.muted)),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    height: s == null ? 2 : 2 + (h - 16) * s * 3.6 / top,
                    decoration: BoxDecoration(color: t.indicator, borderRadius: BorderRadius.circular(3)),
                  ),
                ]),
              ),
          ]),
          if (v.speed != null)
            Positioned(left: 0, right: 0, bottom: 2 + (h - 16) * now / top, child: Container(height: 2, color: now < top * .4 ? t.late : t.ink)),
        ]),
      ),
    ];
  }

  Widget _history(Tones t, List<DayStats> days) {
    final line = widget.line;
    final per = [
      for (final d in days)
        if (d.byLine.where((l) => l.line == line && l.timeS > 600).firstOrNull case final l?) (date: d.date, kmh: l.distM / l.timeS * 3.6, l: l),
    ];
    if (per.isEmpty) {
      return Padding(padding: const EdgeInsets.only(top: 20), child: Text(context.l10n.lineSpeedNoData, style: TextStyle(color: t.muted)));
    }
    double? pooled(bool weekend) {
      var dist = 0.0, time = 0.0;
      for (final p in per) {
        if (isWeekend(p.date) != weekend) continue;
        dist += p.l.distM;
        time += p.l.timeS;
      }
      return time > 0 ? dist / time * 3.6 : null;
    }

    final wd = pooled(false), we = pooled(true);
    final latest = days.last;
    final ranked = ranking(latest, 1000);
    final all = [...ranked.slow, ...ranked.fast.reversed];
    final place = all.indexWhere((r) => r.line == line);
    final top = per.fold(1.0, (m, p) => p.kmh > m ? p.kmh : m);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SizedBox(height: 20),
      Text(context.l10n.lineSpeedLastDays(per.length), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
      const SizedBox(height: 8),
      Row(children: [
        if (wd != null) _tile(t, _dec(wd), context.l10n.lineSpeedKmhWeekdays),
        if (wd != null && we != null) const SizedBox(width: 8),
        if (we != null) _tile(t, _dec(we), context.l10n.lineSpeedKmhWeekends),
      ]),
      if (place >= 0) ...[
        const SizedBox(height: 8),
        Text(context.l10n.lineSpeedRank(place + 1, all.length), style: TextStyle(fontSize: 13, color: t.muted)),
      ],
      const SizedBox(height: 12),
      SizedBox(
        height: 110,
        child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          for (final p in per)
            Expanded(
              child: Tooltip(
                message: context.l10n.lineSpeedDayKmh(p.date, _dec(p.kmh)),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 1),
                  height: 4 + 100 * p.kmh / top,
                  decoration: BoxDecoration(color: isWeekend(p.date) ? t.late : t.onTime, borderRadius: BorderRadius.circular(2)),
                ),
              ),
            ),
        ]),
      ),
      const SizedBox(height: 4),
      Row(children: [
        Text(_label(per.first.date), style: TextStyle(fontSize: 11, color: t.muted)),
        const Spacer(),
        Text(_label(per.last.date), style: TextStyle(fontSize: 11, color: t.muted)),
      ]),
      const SizedBox(height: 6),
      Row(children: [
        Dot(t.onTime),
        const SizedBox(width: 4),
        Text(context.l10n.lineSpeedWeekday, style: TextStyle(fontSize: 12, color: t.muted)),
        const SizedBox(width: 12),
        Dot(t.late),
        const SizedBox(width: 4),
        Text(context.l10n.lineSpeedWeekend, style: TextStyle(fontSize: 12, color: t.muted)),
      ]),
      const SizedBox(height: 12),
      Text(context.l10n.lineSpeedFooter,
          style: TextStyle(fontSize: 12, color: t.muted)),
    ]);
  }

  String _label(String iso) {
    final d = DateTime.tryParse(iso);
    return d == null ? iso : '${_days[d.weekday - 1]} ${d.day}/${d.month}';
  }

  Widget _tile(Tones t, String big, String label) => Expanded(
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: t.surface, borderRadius: BorderRadius.circular(12)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(big, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
            Text(label, style: TextStyle(fontSize: 12, color: t.muted)),
          ]),
        ),
      );
}
