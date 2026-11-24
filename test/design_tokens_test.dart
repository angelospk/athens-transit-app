// The shared design (athens-transit-map docs/design-unify-2026-11.md): line badges in operator colours,
// the ETA style with the board plate (amber digits on a dark plate for live times). SPECIMEN=1 also writes build/specimen-{light,dark}.png in Roboto.
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:athens_transit/core/eta.dart';
import 'package:athens_transit/data/api.dart';
import 'package:athens_transit/data/cache.dart';
import 'package:athens_transit/data/live.dart';
import 'package:athens_transit/data/store.dart';
import 'package:athens_transit/ui/motion_fx.dart' show Tick;
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

  group('board plate', () {
    test('tokens: one plate and one amber in both themes; the edge only in dark', () {
      for (final tn in [Tones.light, Tones.dark]) {
        expect(tn.plate, const Color(0xFF16181B));
        expect(tn.amber, const Color(0xFFFFB000));
      }
      expect(Tones.light.plateEdge.a, 0);
      expect(Tones.dark.plateEdge, const Color(0xFF30353A));
    });

    for (final b in Brightness.values) {
      testWidgets('a live time is amber on the plate (${b.name})', (t) async {
        await t.pumpWidget(host(b: b, const EtaText('5′', live: true)));
        final tn = b == Brightness.light ? Tones.light : Tones.dark;
        final box = t.widget<Container>(find.descendant(of: find.byType(BoardPlate), matching: find.byType(Container)).first);
        final d = box.decoration! as BoxDecoration;
        expect(d.color, const Color(0xFF16181B));
        expect(d.borderRadius, BorderRadius.circular(6));
        expect((d.border! as Border).top.color, tn.plateEdge);
        expect(box.padding, const EdgeInsets.symmetric(horizontal: 8, vertical: 2));
        final rich = t.widget<RichText>(find.descendant(of: find.byType(BoardPlate), matching: find.byType(RichText)).first);
        final span = (rich.text as TextSpan).children!.first as TextSpan; // Text wraps the given span
        expect(span.style!.color, const Color(0xFFFFB000));
        expect(span.style!.fontSize, 24);
        expect(span.style!.fontWeight, FontWeight.w800);
        expect(span.style!.fontFeatures, contains(const FontFeature.tabularFigures()));
        expect((span.children!.last as TextSpan).style!.fontSize, closeTo(16.8, 1e-9)); // the prime: 70 %
      });
    }

    testWidgets('«τώρα»: the word on the plate, 17 / w800, amber', (t) async {
      await t.pumpWidget(host(const EtaText('τώρα', live: true)));
      final w = t.widget<Text>(find.text('τώρα'));
      expect(w.style!.fontSize, 17);
      expect(w.style!.fontWeight, FontWeight.w800);
      expect(w.style!.color, const Color(0xFFFFB000));
      expect(find.byType(BoardPlate), findsOneWidget);
    });

    testWidgets('a timetable or estimate time has no plate: muted number', (t) async {
      await t.pumpWidget(host(const EtaText('~7′', live: false)));
      expect(find.byType(BoardPlate), findsNothing);
      expect(t.widget<Text>(find.text('~7′')).style!.color, Tones.light.muted);
    });

    testWidgets('the first row of a stop: a bigger plate (28; «τώρα» 19)', (t) async {
      await t.pumpWidget(host(const Column(children: [EtaText('5′', live: true, big: true), EtaText('τώρα', live: true, big: true)])));
      final rich = t.widget<RichText>(find.descendant(of: find.byType(BoardPlate), matching: find.byType(RichText)).first);
      expect(((rich.text as TextSpan).children!.first as TextSpan).style!.fontSize, 28);
      expect(t.widget<Text>(find.text('τώρα')).style!.fontSize, 19);
    });

    testWidgets('only the digits flip: the plate itself stays still', (t) async {
      await t.pumpWidget(host(const EtaText('5′', live: true)));
      final plate = find.descendant(of: find.byType(BoardPlate), matching: find.byType(Container)).first;
      expect(find.descendant(of: plate, matching: find.byType(AnimatedSwitcher)), findsOneWidget);
    });

    testWidgets('in a 32 px row the live chip stays 24 tall', (t) async {
      await t.pumpWidget(host(const Center(child: SizedBox(height: 32, child: Row(mainAxisSize: MainAxisSize.min, children: [EtaChip('3′', live: true)])))));
      final chip = find.ancestor(of: find.text('3′'), matching: find.byType(Container)).first;
      expect(t.getSize(chip).height, 24);
    });

    testWidgets('a chip that is not live is muted and still', (t) async {
      await t.pumpWidget(host(const EtaChip('9′', live: false)));
      expect(t.widget<Text>(find.text('9′')).style!.color, Tones.light.muted);
      expect(find.byType(Tick), findsNothing);
    });

    testWidgets('the live chip grows with large text instead of clipping it', (t) async {
      await t.pumpWidget(host(const MediaQuery(data: MediaQueryData(textScaler: TextScaler.linear(2)), child: Center(child: EtaChip('3′', live: true)))));
      final chip = find.ancestor(of: find.text('3′'), matching: find.byType(Container)).first;
      expect(t.getSize(chip).height, greaterThan(24));
    });

    testWidgets('the live chip: height 24, plate fill, amber text; the other chip keeps the token style', (t) async {
      await t.pumpWidget(host(const Column(children: [EtaChip('3′', live: true), EtaChip('9′', live: false)])));
      await t.pumpAndSettle();
      expect(t.getSize(find.widgetWithText(Container, '3′').first).height, 24);
      final box = find.ancestor(of: find.text('3′'), matching: find.byType(Container)).first;
      expect((t.widget<Container>(box).decoration! as BoxDecoration).color, const Color(0xFF16181B));
      expect(t.widget<Text>(find.text('3′')).style!.color, const Color(0xFFFFB000));
      expect(t.widget<Text>(find.text('9′')).style!.color, Tones.light.muted);
    });

    testWidgets('the digits flip once on a change (150 ms); nothing animates when animations are off', (t) async {
      Widget at(String v, {bool off = false}) => host(MediaQuery(
          data: MediaQueryData(disableAnimations: off), child: EtaText(v, live: true)));
      await t.pumpWidget(at('5′'));
      await t.pumpWidget(at('4′'));
      await t.pump(const Duration(milliseconds: 60));
      expect(find.text('5′', findRichText: true), findsOneWidget); // the old digits still leave
      expect(find.text('4′', findRichText: true), findsOneWidget);
      await t.pump(const Duration(milliseconds: 150));
      expect(find.text('5′', findRichText: true), findsNothing);
      expect(find.text('4′', findRichText: true), findsOneWidget);

      await t.pumpWidget(at('3′', off: true));
      await t.pumpWidget(at('2′', off: true));
      expect(find.text('3′', findRichText: true), findsNothing);
      expect(find.text('2′', findRichText: true), findsOneWidget);
    });
  });

  testWidgets('an arrival row: «μετά» for the next times, the delay in the late colour; the time is on the plate', (t) async {
    await t.pumpWidget(host(ArrivalRow(first: _a('11', 'Ν. ΕΛΒΕΤΙΑ', 120, delayS: 480), then: [_a('11', 'Ν. ΕΛΒΕΤΙΑ', 1380)])));
    expect(find.text('μετά 23′'), findsOneWidget);
    expect(t.widget<Text>(find.text('αργεί 8′')).style!.color, Tones.light.late);
    expect(find.byType(BoardPlate), findsOneWidget);
  });

  testWidgets('a timetable row: no plate, «από το πρόγραμμα»', (t) async {
    await t.pumpWidget(host(ArrivalRow(first: _a('11', 'Ν. ΕΛΒΕΤΙΑ', 1320), timetable: true)));
    expect(find.byType(BoardPlate), findsNothing);
    expect(find.text('από το πρόγραμμα'), findsOneWidget);
    expect(find.text('22′'), findsOneWidget);
  });

  testWidgets('specimen', (t) async {
    final fonts = '${Platform.environment['FLUTTER_ROOT'] ?? '${Platform.environment['HOME']}/flutter'}/bin/cache/artifacts/material_fonts';
    final loader = FontLoader('Roboto');
    for (final w in ['Regular', 'Medium', 'Bold', 'Black']) {
      loader.addFont(Future.value(ByteData.sublistView(File('$fonts/Roboto-$w.ttf').readAsBytesSync())));
    }
    await loader.load();
    await t.binding.setSurfaceSize(const Size(390, 520));
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
                  ArrivalRow(first: _a('026', 'ΒΟΤΑΝΙΚΟΣ', 120, delayS: 30), then: [_a('026', 'ΒΟΤΑΝΙΚΟΣ', 1080)]),
                  ArrivalRow(first: _a('A2', 'ΒΟΥΛΑ', 840, left: 3)),
                  ArrivalRow(first: _a('X95', 'ΑΕΡΟΔΡΟΜΙΟ', 1320), timetable: true),
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
