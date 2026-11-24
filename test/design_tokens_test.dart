// The shared design (athens-transit-map docs/design-unify-2026-11.md): line badges in operator colours,
// the ETA style with the live mark. SPECIMEN=1 also writes build/specimen-{light,dark}.png in Roboto.
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:athens_transit/core/eta.dart';
import 'package:athens_transit/data/api.dart';
import 'package:athens_transit/data/cache.dart';
import 'package:athens_transit/data/live.dart';
import 'package:athens_transit/data/store.dart';
import 'package:athens_transit/ui/theme.dart';
import 'package:athens_transit/ui/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart' show FontLoader;
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

Arrival _a(String line, String to, int etaS, {int? delayS, int? left}) => Arrival(
    line: line, variant: 'v', headsign: to, vehicleId: 'x$line', etaS: etaS, stopsLeft: left, delayS: delayS, positionAt: 0);

void main() {
  late AppStore store;
  late Api api;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    store = AppStore(await SharedPreferences.getInstance());
    api = Api(client: MockClient((_) async => http.Response('', 503)), cache: DiskCache(dir: Directory.systemTemp.createTempSync()));
    operatorColors.value = const {
      '11': LineColor(Color(0xFFF29F1C), Colors.black),
      '026': LineColor(Color(0xFF1E40D8), Colors.white),
      'A2': LineColor(Color(0xFF1E40D8), Colors.white),
    };
  });
  tearDown(() => operatorColors.value = const {});

  Widget host(Widget child, {Brightness b = Brightness.light}) => Deps(
        store: store,
        live: LiveHub(api),
        api: api,
        child: MaterialApp(theme: buildTheme(b), home: Scaffold(body: child)),
      );

  test('a line takes its operator colour; one of my lines keeps its palette slot; unknown is neutral', () {
    expect(lineColor(store, '11').bg, const Color(0xFFF29F1C));
    expect(lineColor(store, 'X95').bg, const Color(0xFFEFF0EC));
    store.toggleMyLine('026');
    expect(lineColor(store, '026').bg, palette[0].bg);
  });

  test('hexColor reads #rrggbb only', () {
    expect(hexColor('#1a56c4'), const Color(0xFF1A56C4));
    expect(hexColor('1a56c4'), isNull);
    expect(hexColor('#fff'), isNull);
  });

  testWidgets('a live time has the live mark; an estimate has none; «τώρα» is in the accent', (t) async {
    await t.pumpWidget(host(const Column(children: [EtaText('5′', live: true), EtaText('~7′', live: false), EtaText('τώρα', live: true)])));
    final marks = find.byType(LiveMark);
    expect(marks, findsNWidgets(2));
    expect(find.descendant(of: find.widgetWithText(EtaText, '~7′'), matching: find.byType(LiveMark)), findsNothing);
    final now = t.widget<Text>(find.text('τώρα'));
    expect(now.style!.color, Tones.light.accent);
    expect(t.widget<Text>(find.text('~7′')).style!.color, Tones.light.muted);
  });

  testWidgets('an arrival row: «μετά» for the next times, the delay in the late colour', (t) async {
    await t.pumpWidget(host(ArrivalRow(first: _a('11', 'Ν. ΕΛΒΕΤΙΑ', 120, delayS: 480), then: [_a('11', 'Ν. ΕΛΒΕΤΙΑ', 1380)])));
    expect(find.text('μετά 23′'), findsOneWidget);
    expect(t.widget<Text>(find.text('αργεί 8′')).style!.color, Tones.light.late);
    expect(find.byType(LiveMark), findsOneWidget);
  });

  testWidgets('specimen', (t) async {
    final fonts = '${Platform.environment['FLUTTER_ROOT'] ?? '${Platform.environment['HOME']}/flutter'}/bin/cache/artifacts/material_fonts';
    final loader = FontLoader('Roboto');
    for (final w in ['Regular', 'Medium', 'Bold', 'Black']) {
      loader.addFont(Future.value(ByteData.sublistView(File('$fonts/Roboto-$w.ttf').readAsBytesSync())));
    }
    await loader.load();
    await t.binding.setSurfaceSize(const Size(400, 560));
    for (final b in Brightness.values) {
      final key = GlobalKey();
      await t.pumpWidget(host(
        b: b,
        RepaintBoundary(
          key: key,
          child: Builder(builder: (c) {
            final tn = c.tones;
            return Container(
              color: tn.ground,
              padding: const EdgeInsets.all(16),
              child: Container(
                decoration: Ds.card(tn),
                padding: const EdgeInsets.fromLTRB(14, 10, 12, 4),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Σύνταγμα', style: Ds.title.copyWith(color: tn.ink)),
                  Text('στάση λεωφορείων · 70 μ', style: Ds.meta.copyWith(color: tn.muted)),
                  const SizedBox(height: 4),
                  ArrivalRow(first: _a('11', 'Ν. ΕΛΒΕΤΙΑ', 20, delayS: 480), then: [_a('11', 'Ν. ΕΛΒΕΤΙΑ', 1380)]),
                  ArrivalRow(first: _a('026', 'ΒΟΤΑΝΙΚΟΣ', 300, delayS: 30), then: [_a('026', 'ΒΟΤΑΝΙΚΟΣ', 1080)], big: true),
                  ArrivalRow(first: _a('A2', 'ΒΟΥΛΑ', 540, left: 3)),
                  ArrivalRow(first: _a('X95', 'ΑΕΡΟΔΡΟΜΙΟ', 720), estimate: true),
                  const SizedBox(height: 8),
                  const Wrap(spacing: 6, children: [LineBadge('11'), LineBadge('026'), LineBadge('X95'), LineBadge('A2', big: true)]),
                  const SizedBox(height: 8),
                ]),
              ),
            );
          }),
        ),
      ));
      await t.pumpAndSettle();
      if (Platform.environment['SPECIMEN'] == null) continue;
      await t.runAsync(() async {
        final boundary = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        final img = await boundary.toImage(pixelRatio: 2);
        final png = await img.toByteData(format: ui.ImageByteFormat.png);
        File('build/specimen-${b.name}.png')
          ..createSync(recursive: true)
          ..writeAsBytesSync(png!.buffer.asUint8List());
      });
    }
  });
}
