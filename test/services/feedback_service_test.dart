import 'package:flutter_test/flutter_test.dart';

import 'package:block_fusion/services/feedback_service.dart';

void main() {
  // These calls reach platform channels (audio, vibration), which need a
  // binding even when there is no plugin behind them.
  TestWidgetsFlutterBinding.ensureInitialized();

  group('FeedbackService', () {
    test('starts audible and buzzing', () {
      final feedback = FeedbackService();

      expect(feedback.soundVolume, FeedbackService.defaultVolume);
      expect(feedback.soundEnabled, isTrue);
      expect(feedback.hapticStrength, HapticStrength.medium);
      expect(feedback.hapticsEnabled, isTrue);
    });

    test('volume is clamped to 0..1 in the constructor and the setter', () {
      expect(FeedbackService(soundVolume: 4).soundVolume, 1.0);
      expect(FeedbackService(soundVolume: -2).soundVolume, 0.0);

      final feedback = FeedbackService()..setSoundVolume(9);
      expect(feedback.soundVolume, 1.0);
      feedback.setSoundVolume(-9);
      expect(feedback.soundVolume, 0.0);
    });

    test('zero volume counts as sound off', () {
      final feedback = FeedbackService()..setSoundVolume(0);

      expect(feedback.soundEnabled, isFalse);
    });

    test('off strength counts as haptics off', () {
      final feedback = FeedbackService()
        ..setHapticStrength(HapticStrength.off);

      expect(feedback.hapticsEnabled, isFalse);
    });

    test('changing either setting notifies listeners', () {
      final feedback = FeedbackService();
      var notifications = 0;
      feedback.addListener(() => notifications++);

      feedback
        ..setSoundVolume(0.3)
        ..setHapticStrength(HapticStrength.strong);

      expect(notifications, 2);
    });

    test('setting a value it already has notifies nobody', () {
      final feedback = FeedbackService();
      var notifications = 0;
      feedback.addListener(() => notifications++);

      feedback
        ..setSoundVolume(FeedbackService.defaultVolume)
        ..setHapticStrength(HapticStrength.medium);

      expect(notifications, 0);
    });

    test('an unknown stored strength falls back to medium', () {
      // A save from a future version, or a corrupted one, must not leave
      // the game with no vibration setting at all.
      expect(HapticStrength.fromName('no-such-strength'), HapticStrength.medium);
      expect(HapticStrength.fromName(null), HapticStrength.medium);
      expect(HapticStrength.fromName('strong'), HapticStrength.strong);
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

    test('silenced and stilled, the same events are still safe', () {
      final feedback =
          FeedbackService(soundVolume: 0, hapticStrength: HapticStrength.off);

      expect(feedback.piecePlaced, returnsNormally);
      expect(() => feedback.lineCleared(lines: 2, sameColor: true),
          returnsNormally);
      expect(feedback.gameOver, returnsNormally);
    });
  });
}
