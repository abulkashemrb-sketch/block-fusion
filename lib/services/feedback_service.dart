import 'dart:async';

import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// The game's sound and vibration, behind one switch each.
///
/// Every method is fire-and-forget and swallows its own failures. Audio is
/// the most environment-dependent thing in the app — a browser that has not
/// seen a user gesture yet refuses to play, a device may have no vibrator,
/// an asset may be missing from a stripped build — and none of that is
/// worth interrupting a game over.
class FeedbackService extends ChangeNotifier {
  FeedbackService({this.soundEnabled = true, this.hapticsEnabled = true});

  static const List<String> _clips = [
    'place.wav',
    'clear.wav',
    'combo.wav',
    'bonus.wav',
    'gameover.wav',
  ];

  bool soundEnabled;
  bool hapticsEnabled;

  bool _warmed = false;

  /// Decodes the clips once so the first placement is not silent while the
  /// device reads them off disk.
  Future<void> warmUp() async {
    if (_warmed) return;
    _warmed = true;
    try {
      await FlameAudio.audioCache.loadAll(_clips);
    } catch (error) {
      _log('warmUp', error);
    }
  }

  void setSoundEnabled(bool value) {
    if (soundEnabled == value) return;
    soundEnabled = value;
    notifyListeners();
  }

  void setHapticsEnabled(bool value) {
    if (hapticsEnabled == value) return;
    hapticsEnabled = value;
    notifyListeners();
  }

  void piecePlaced() {
    _play('place.wav');
    _tap(HapticFeedback.selectionClick);
  }

  void lineCleared({required int lines, required bool sameColor}) {
    _play(lines >= 2 ? 'combo.wav' : 'clear.wav');
    if (sameColor) _play('bonus.wav');
    // A bigger clear should feel bigger, not just sound bigger.
    _tap(lines >= 2 ? HapticFeedback.mediumImpact : HapticFeedback.lightImpact);
  }

  void gameOver() {
    _play('gameover.wav');
    _tap(HapticFeedback.heavyImpact);
  }

  void _play(String clip) {
    if (!soundEnabled) return;
    // Both halves matter. The synchronous throw happens when the platform
    // channel is missing entirely; the rejected future happens when the
    // engine is there but refuses — a browser that has not seen a user
    // gesture yet is the common case, and an unhandled rejection there
    // would surface as a console error on every placement.
    _guard('play $clip', () => FlameAudio.play(clip));
  }

  void _tap(Future<void> Function() effect) {
    if (!hapticsEnabled) return;
    // Web has no vibration behind HapticFeedback, so skip the channel round
    // trip rather than rely on it being a silent no-op.
    if (kIsWeb) return;
    _guard('haptic', effect);
  }

  void _guard(String what, Future<Object?> Function() action) {
    try {
      unawaited(action().then<void>(
        (_) {},
        onError: (Object error) => _log(what, error),
      ));
    } catch (error) {
      _log(what, error);
    }
  }

  void _log(String what, Object error) {
    if (kDebugMode) debugPrint('FeedbackService.$what failed: $error');
  }
}
