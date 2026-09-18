import 'package:flutter_test/flutter_test.dart';

import 'package:block_fusion/services/feedback_service.dart';

void main() {
  // These calls reach platform channels (audio, vibration), which need a
  // binding even when there is no plugin behind them.
  TestWidgetsFlutterBinding.ensureInitialized();

  group('FeedbackService', () {
    test('starts with sound and haptics on', () {
      final feedback = FeedbackService();

      expect(feedback.soundEnabled, isTrue);
      expect(feedback.hapticsEnabled, isTrue);
    });

    test('toggling notifies listeners', () {
      final feedback = FeedbackService();
      var notifications = 0;
      feedback.addListener(() => notifications++);

      feedback.setSoundEnabled(false);
      feedback.setHapticsEnabled(false);

      expect(notifications, 2);
      expect(feedback.soundEnabled, isFalse);
      expect(feedback.hapticsEnabled, isFalse);
    });

    test('setting a value it already has notifies nobody', () {
      final feedback = FeedbackService();
      var notifications = 0;
      feedback.addListener(() => notifications++);

      feedback.setSoundEnabled(true);

      expect(notifications, 0);
    });

    test('every event is safe to call with no audio engine behind it', () {
      // Widget tests have no audio plugin, and a browser refuses to play
      // before a user gesture. Neither may throw — the sound is a garnish
      // and must never cost the player their move.
      final feedback = FeedbackService();

      expect(feedback.piecePlaced, returnsNormally);
      expect(() => feedback.lineCleared(lines: 1, sameColor: false),
          returnsNormally);
      expect(() => feedback.lineCleared(lines: 3, sameColor: true),
          returnsNormally);
      expect(feedback.gameOver, returnsNormally);
    });

    test('muted, the same events are still safe', () {
      final feedback =
          FeedbackService(soundEnabled: false, hapticsEnabled: false);

      expect(feedback.piecePlaced, returnsNormally);
      expect(() => feedback.lineCleared(lines: 2, sameColor: true),
          returnsNormally);
      expect(feedback.gameOver, returnsNormally);
    });
  });
}
