import 'package:flutter_test/flutter_test.dart';

import 'package:block_fusion/main.dart';

void main() {
  testWidgets('Home screen shows the game title', (WidgetTester tester) async {
    await tester.pumpWidget(const BlockFusionApp());

    expect(find.text('BLOCK FUSION'), findsOneWidget);
  });
}
