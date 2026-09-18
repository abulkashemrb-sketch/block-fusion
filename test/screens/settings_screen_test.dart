import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:block_fusion/screens/settings_screen.dart';
import 'package:block_fusion/services/feedback_service.dart';
import 'package:block_fusion/theme/app_theme.dart';

void main() {
  Future<FeedbackService> pumpSettings(WidgetTester tester) async {
    final feedback = FeedbackService();
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: SettingsScreen(feedback: feedback),
      ),
    );
    await tester.pumpAndSettle();
    return feedback;
  }

  testWidgets('both switches start on and reflect the service',
      (tester) async {
    await pumpSettings(tester);

    final switches = tester.widgetList<Switch>(find.byType(Switch)).toList();
    expect(switches, hasLength(2));
    expect(switches.every((s) => s.value), isTrue);
  });

  testWidgets('turning sound off reaches the service', (tester) async {
    final feedback = await pumpSettings(tester);

    await tester.tap(find.byType(Switch).first);
    await tester.pumpAndSettle();

    expect(feedback.soundEnabled, isFalse);
    // And the switch redrew from the service rather than its own state.
    expect(tester.widgetList<Switch>(find.byType(Switch)).first.value, isFalse);
  });

  testWidgets('turning vibration off reaches the service', (tester) async {
    final feedback = await pumpSettings(tester);

    await tester.tap(find.byType(Switch).last);
    await tester.pumpAndSettle();

    expect(feedback.hapticsEnabled, isFalse);
  });

  testWidgets('every special piece is explained', (tester) async {
    // The bomb and the wildcard are rare enough that a player meeting one
    // mid-game needs somewhere to look it up.
    await pumpSettings(tester);

    expect(find.text('Wildcard'), findsOneWidget);
    expect(find.text('Bomb'), findsOneWidget);
    expect(find.textContaining('3x3'), findsOneWidget);

    // The rest is below the fold, and a ListView does not build what it
    // cannot show — so scroll to it the way a player would.
    await tester.drag(find.byType(ListView), const Offset(0, -400));
    await tester.pumpAndSettle();

    expect(find.text('Locked cell'), findsOneWidget);
    expect(find.textContaining('two clears'), findsOneWidget);
    expect(find.textContaining('none of the three pieces fits'), findsOneWidget);
  });
}
