import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:block_fusion/screens/settings_screen.dart';
import 'package:block_fusion/services/feedback_service.dart';
import 'package:block_fusion/theme/app_theme.dart';

/// Records what the service decided to do, instead of doing it.
///
/// Subclassing rather than mocking: the seam is two methods wide, and the
/// decisions under test — which clip, how long a buzz — are exactly what
/// those two methods are handed.
class _RecordingFeedback extends FeedbackService {
  final List<String> sounds = [];
  final List<int> buzzes = [];

  @override
  void playClip(String clip, double volume) => sounds.add(clip);

  @override
  void vibrate({
    required int duration,
    required int amplitude,
    List<int>? pattern,
  }) =>
      buzzes.add(duration);

  void clear() {
    sounds.clear();
    buzzes.clear();
  }
}

void main() {
  Future<T> pumpWith<T extends FeedbackService>(
    WidgetTester tester,
    T feedback,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: SettingsScreen(feedback: feedback),
      ),
    );
    await tester.pumpAndSettle();
    return feedback;
  }

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

  testWidgets('the volume slider shows the current level', (tester) async {
    await pumpSettings(tester);

    expect(find.textContaining('Sound'), findsOneWidget);
    expect(find.textContaining('70%'), findsOneWidget);
    expect(tester.widget<Slider>(find.byType(Slider)).value,
        FeedbackService.defaultVolume);
  });

  testWidgets('dragging the slider changes the volume', (tester) async {
    final feedback = await pumpSettings(tester);

    await tester.drag(find.byType(Slider), const Offset(-300, 0));
    await tester.pumpAndSettle();

    expect(feedback.soundVolume, lessThan(FeedbackService.defaultVolume));
    // And the label redrew from the service rather than its own state.
    final percent = (feedback.soundVolume * 100).round();
    expect(find.textContaining('$percent%'), findsOneWidget);
  });

  testWidgets('the volume can be taken all the way to silence',
      (tester) async {
    final feedback = await pumpSettings(tester);

    await tester.drag(find.byType(Slider), const Offset(-1000, 0));
    await tester.pumpAndSettle();

    expect(feedback.soundVolume, 0);
    expect(feedback.soundEnabled, isFalse);
  });

  testWidgets('every vibration strength is offered', (tester) async {
    await pumpSettings(tester);

    for (final strength in HapticStrength.values) {
      expect(find.text(strength.label), findsOneWidget);
    }
  });

  testWidgets('picking a vibration strength reaches the service',
      (tester) async {
    final feedback = await pumpSettings(tester);

    await tester.tap(find.text('Strong'));
    await tester.pumpAndSettle();

    expect(feedback.hapticStrength, HapticStrength.strong);
  });

  testWidgets('vibration can be turned off entirely', (tester) async {
    final feedback = await pumpSettings(tester);

    await tester.tap(find.text('Off'));
    await tester.pumpAndSettle();

    expect(feedback.hapticStrength, HapticStrength.off);
    expect(feedback.hapticsEnabled, isFalse);
  });

  testWidgets('the volume preview is the loud clip, not the quiet one',
      (tester) async {
    // The first version previewed with piecePlaced(): the quietest clip in
    // the set, scaled down again on top, so the slider seemed to do
    // nothing — and it buzzed, which a player adjusting sound did not ask
    // for.
    final feedback = await pumpWith(tester, _RecordingFeedback());
    feedback.clear();

    await tester.drag(find.byType(Slider), const Offset(-100, 0));
    await tester.pumpAndSettle();

    expect(feedback.sounds, contains('clear.wav'));
    expect(feedback.sounds, isNot(contains('place.wav')));
    expect(feedback.buzzes, isEmpty, reason: 'a volume change must not buzz');
  });

  testWidgets('the vibration preview buzzes and stays silent',
      (tester) async {
    final feedback = await pumpWith(tester, _RecordingFeedback());
    feedback.clear();

    await tester.tap(find.text('Strong'));
    await tester.pumpAndSettle();

    expect(feedback.buzzes, isNotEmpty);
    expect(feedback.sounds, isEmpty,
        reason: 'a vibration change must not make a noise');
  });

  testWidgets('a stronger setting buzzes for longer', (tester) async {
    final feedback = await pumpWith(tester, _RecordingFeedback());

    await tester.tap(find.text('Light'));
    await tester.pumpAndSettle();
    final light = feedback.buzzes.last;

    await tester.tap(find.text('Strong'));
    await tester.pumpAndSettle();

    expect(feedback.buzzes.last, greaterThan(light));
  });

  testWidgets('every special piece is explained', (tester) async {
    // The bomb and the wildcard are rare enough that a player meeting one
    // mid-game needs somewhere to look it up.
    await pumpSettings(tester);

    // Each of these is scrolled to in turn: a ListView does not build what
    // it cannot show, and the controls above them change height whenever
    // the settings do, so a fixed scroll distance would rot.
    for (final needle in ['Wildcard', 'Bomb']) {
      await tester.scrollUntilVisible(find.text(needle), 200);
      expect(find.text(needle), findsOneWidget);
    }

    // The rest is below the fold, and a ListView does not build what it
    // cannot show — so scroll to it the way a player would. Scrolling until
    // it appears rather than by a fixed distance, because the controls
    // above it change height whenever the settings do.
    await tester.scrollUntilVisible(find.text('Locked cell'), 200);

    expect(find.text('Locked cell'), findsOneWidget);
    expect(find.textContaining('two clears'), findsOneWidget);
    expect(find.textContaining('none of the three pieces fits'), findsOneWidget);
  });
}
