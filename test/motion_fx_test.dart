import 'package:athens_transit/ui/motion_fx.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _app(bool off, Widget child) => Directionality(
      textDirection: TextDirection.ltr,
      child: MediaQuery(data: MediaQueryData(disableAnimations: off), child: child),
    );

void main() {
  testWidgets('reduced motion: no animation, the child as is', (tester) async {
    await tester.pumpWidget(_app(true, const Column(children: [
      Enter(key: ValueKey('a'), i: 2, child: Text('row')),
      Tick(value: "3'", child: Text("3'")),
    ])));
    expect(find.byType(Animate), findsNothing);
    expect(find.text('row'), findsOneWidget);
    expect(find.text("3'"), findsOneWidget);
  });

  testWidgets('iOS Reduce Motion (not disableAnimations there): no animation either', (tester) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(reduceMotion: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await tester.pumpWidget(_app(false, const Column(children: [
      Enter(key: ValueKey('a'), child: Text('row')),
      Tick(value: "3'", child: Text("3'")),
    ])));
    expect(find.byType(Animate), findsNothing);
  });

  testWidgets('motion on: rows enter, a changed value plays again, an equal one does not', (tester) async {
    // Not const: every pump rebuilds Tick, as a live refresh of the sheet does.
    Widget sheet(String minutes) => _app(false, Column(children: [
          Enter(key: const ValueKey('a'), child: Text('row')),
          Tick(value: minutes, child: Text(minutes)),
        ]));

    await tester.pumpWidget(sheet("3'"));
    expect(find.byType(Animate), findsNWidgets(2));
    await tester.pumpAndSettle();
    final before = tester.state(find.byType(Animate).last);

    await tester.pumpWidget(sheet("3'"));
    expect(tester.state(find.byType(Animate).last), same(before));
    await tester.pump(const Duration(milliseconds: 50));
    expect(tester.hasRunningAnimations, isFalse);

    await tester.pumpWidget(sheet("2'"));
    expect(tester.state(find.byType(Animate).last), isNot(same(before)));
    await tester.pump(const Duration(milliseconds: 50));
    expect(tester.hasRunningAnimations, isTrue);
    await tester.pumpAndSettle();
  });
}
