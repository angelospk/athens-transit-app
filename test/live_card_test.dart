// The live card has only an Android side. On iOS its channel has no handler, so every call must be a
// quiet no-op: the rule service calls show and takeEnded on each tick.
import 'package:flutter_test/flutter_test.dart';
import 'package:live_card/live_card.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('show is a no-op without the native side', () async {
    await LiveCard.show(id: 1, title: 't', text: 'x');
  });

  test('takeEnded is empty without the native side', () async {
    expect(await LiveCard.takeEnded(), isEmpty);
  });

  test('takeOpen is null without the native side', () async {
    expect(await LiveCard.takeOpen(), isNull);
  });
}
