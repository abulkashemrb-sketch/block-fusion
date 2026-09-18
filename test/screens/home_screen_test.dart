import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:block_fusion/main.dart';
import 'package:block_fusion/services/auth_service.dart';
import 'package:block_fusion/services/feedback_service.dart';
import 'package:block_fusion/screens/home_screen.dart';
import 'package:block_fusion/screens/settings_screen.dart';
import 'package:block_fusion/theme/app_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pumpWithScope(WidgetTester tester) async {
    await tester.pumpWidget(
      AppScope(
        auth: AuthService(),
        feedback: FeedbackService(),
        child: MaterialApp(theme: AppTheme.dark, home: const HomeScreen()),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('the settings gear is on the home screen', (tester) async {
    await pumpWithScope(tester);

    expect(find.byIcon(Icons.settings), findsOneWidget);
  });

  testWidgets('the gear is reachable, not buried under the menu column',
      (tester) async {
    // The menu is painted over the gear in the same Stack, so a layout
    // change that lets the column swallow taps would hide it without
    // hiding it.
    await pumpWithScope(tester);

    await tester.tap(find.byIcon(Icons.settings));
    await tester.pumpAndSettle();

    expect(find.byType(SettingsScreen), findsOneWidget);
  });

  testWidgets('without a scope the gear is absent rather than broken',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.dark, home: const HomeScreen()),
    );
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.settings), findsNothing);
    expect(find.text('PLAY'), findsOneWidget);
  });
}
