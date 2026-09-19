import 'dart:async';

import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// How hard the phone buzzes.
///
/// Stepped rather than continuous because the platform is: Flutter exposes
/// a handful of named impacts, not an amplitude. A slider would let the
/// player move through a range where nothing changed, which is worse than
/// admitting there are four settings.
enum HapticStrength {
  off('Off'),
  light('Light'),
  medium('Medium'),
  strong('Strong');

  const HapticStrength(this.label);

  final String label;

  static HapticStrength fromName(String? name) =>
      HapticStrength.values.where((s) => s.name == name).firstOrNull ??
      HapticStrength.medium;
}

/// The game's sound and vibration, and how much of each the player wants.
///
/// Every method is fire-and-forget and swallows its own failures. Audio is
/// the most environment-dependent thing in the app — a browser that has not
/// seen a user gesture yet refuses to play, a device may have no vibrator,
/// an asset may be missing from a stripped build — and none of that is
/// worth interrupting a game over.
class FeedbackService extends ChangeNotifier {
  FeedbackService({
    double soundVolume = defaultVolume,
    this.hapticStrength = HapticStrength.medium,
  }) : _soundVolume = soundVolume.clamp(0.0, 1.0);

  static const double defaultVolume = 0.7;

  static const List<String> _clips = [
    'place.wav',
    'clear.wav',
    'combo.wav',
    'bonus.wav',
    'gameover.wav',
  ];

  /// Quieter than the clear and combo sounds, because it fires on every
  /// single placement and would wear thin at the same level.
  static const double _placeVolumeScale = 0.55;

  double _soundVolume;
  HapticStrength hapticStrength;

  bool _warmed = false;

  double get soundVolume => _soundVolume;
  bool get soundEnabled => _soundVolume > 0;
  bool get hapticsEnabled => hapticStrength != HapticStrength.off;

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

  void setSoundVolume(double value) {
    final clamped = value.clamp(0.0, 1.0);
    if (_soundVolume == clamped) return;
    _soundVolume = clamped;
    notifyListeners();
  }

  void setHapticStrength(HapticStrength value) {
    if (hapticStrength == value) return;
    hapticStrength = value;
    notifyListeners();
  }

  void piecePlaced() {
    _play('place.wav', scale: _placeVolumeScale);
    _tap(_lighterThanSet);
  }

  void lineCleared({required int lines, required bool sameColor}) {
    _play(lines >= 2 ? 'combo.wav' : 'clear.wav');
    if (sameColor) _play('bonus.wav');
    // A bigger clear should feel bigger, not just sound bigger — but never
    // harder than the player asked for.
    _tap(lines >= 2 ? _atSet : _lighterThanSet);
  }

  void gameOver() {
    _play('gameover.wav');
    _tap(_atSet);
  }

  /// The impact the player chose.
  Future<void> Function()? get _atSet => switch (hapticStrength) {
        HapticStrength.off => null,
        HapticStrength.light => HapticFeedback.selectionClick,
        HapticStrength.medium => HapticFeedback.lightImpact,
        HapticStrength.strong => HapticFeedback.heavyImpact,
      };

  /// One step down, for events that happen constantly.
  Future<void> Function()? get _lighterThanSet => switch (hapticStrength) {
        HapticStrength.off => null,
        HapticStrength.light => HapticFeedback.selectionClick,
        HapticStrength.medium => HapticFeedback.selectionClick,
        HapticStrength.strong => HapticFeedback.mediumImpact,
      };

  void _play(String clip, {double scale = 1.0}) {
    final volume = _soundVolume * scale;
    if (volume <= 0) return;
    // Both halves matter. The synchronous throw happens when the platform
    // channel is missing entirely; the rejected future happens when the
    // engine is there but refuses — a browser that has not seen a user
    // gesture yet is the common case, and an unhandled rejection there
    // would surface as a console error on every placement.
    _guard('play $clip', () => FlameAudio.play(clip, volume: volume));
  }

  void _tap(Future<void> Function()? effect) {
    if (effect == null) return;
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
