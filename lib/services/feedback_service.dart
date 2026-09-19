import 'dart:async';

import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:vibration/vibration.dart';

/// How hard the phone buzzes.
///
/// Stepped rather than continuous because a buzz is judged by whether it
/// was noticed, not by a percentage: four clearly different settings are
/// more useful than a hundred the hand cannot tell apart.
enum HapticStrength {
  off('Off', 0, 0),
  light('Light', 12, 90),
  medium('Medium', 22, 150),
  strong('Strong', 40, 230);

  const HapticStrength(this.label, this.milliseconds, this.amplitude);

  final String label;

  /// How long the buzz lasts. The most important of the two — below about
  /// 10ms a vibration motor has not finished spinning up and the player
  /// feels nothing at all.
  final int milliseconds;

  /// 1-255 on Android devices whose motor supports amplitude control.
  /// Ignored elsewhere, which is why duration carries the difference.
  final int amplitude;

  bool get isOff => this == HapticStrength.off;

  static HapticStrength fromName(String? name) =>
      HapticStrength.values.where((s) => s.name == name).firstOrNull ??
      HapticStrength.medium;
}

/// The game's sound and vibration, and how much of each the player wants.
///
/// Vibration goes through the vibration plugin rather than Flutter's
/// [HapticFeedback]. HapticFeedback plays a *system* haptic: its strength
/// is whatever the OS has been set to, several Android skins damp it, and
/// on the devices this was tested on it was too faint to notice at all.
/// Driving the motor directly is the only way a "Strong" setting can
/// actually feel strong. [HapticFeedback] stays as the fallback for
/// devices that report no vibrator of their own.
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
  bool? _hasVibrator;

  double get soundVolume => _soundVolume;
  bool get soundEnabled => _soundVolume > 0;
  bool get hapticsEnabled => !hapticStrength.isOff;

  /// Decodes the clips and asks the device about its motor once, so the
  /// first placement is neither silent nor still while that is worked out.
  Future<void> warmUp() async {
    if (_warmed) return;
    _warmed = true;
    try {
      await FlameAudio.audioCache.loadAll(_clips);
    } catch (error) {
      _log('warmUp audio', error);
    }
    try {
      _hasVibrator = kIsWeb ? false : await Vibration.hasVibrator();
    } catch (error) {
      _log('warmUp vibrator', error);
      _hasVibrator = false;
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
    // Two thirds the length: this fires on every move, and at full strength
    // it turns into a constant buzz rather than a series of taps.
    _buzz(scale: 0.66);
  }

  void lineCleared({required int lines, required bool sameColor}) {
    _play(lines >= 2 ? 'combo.wav' : 'clear.wav');
    if (sameColor) _play('bonus.wav');
    // A bigger clear should feel bigger. Capped, so a five-line combo on
    // the Strong setting is emphatic rather than alarming.
    _buzz(scale: lines >= 2 ? 1.6 : 1.0);
  }

  /// Plays a clearly audible clip and nothing else, for the volume slider.
  ///
  /// Deliberately not [piecePlaced]: that is the quietest clip in the set
  /// and is scaled down again on top, so at anything but full volume it is
  /// inaudible — which reads as the slider doing nothing. And it must not
  /// buzz: a player adjusting sound has not asked to be vibrated at.
  void previewSound() => _play('clear.wav');

  /// Buzzes at the current strength and stays silent, for the vibration
  /// picker. The mirror of the problem above: a player adjusting vibration
  /// has not asked for a noise.
  void previewHaptics() => _buzz();

  void gameOver() {
    _play('gameover.wav');
    // Two pulses, which reads as an ending rather than one more clear.
    _buzz(pattern: const [0, 1, 90, 1], scale: 1.4);
  }

  /// Buzzes at the player's setting, scaled for the occasion.
  ///
  /// [pattern] is in units of the setting's duration — `[0, 1, 90, 1]`
  /// means "wait 0, buzz for one unit, wait 90ms, buzz again" — so the
  /// shape of a pattern survives a change of strength.
  void _buzz({double scale = 1.0, List<int>? pattern}) {
    final strength = hapticStrength;
    if (strength.isOff || kIsWeb) return;

    final duration = (strength.milliseconds * scale).round().clamp(8, 400);
    final amplitude = (strength.amplitude * scale).round().clamp(1, 255);

    vibrate(
      duration: duration,
      amplitude: amplitude,
      pattern: pattern == null
          ? null
          : [
              for (final unit in pattern)
                // Odd entries are buzzes measured in units of the chosen
                // duration; even entries are waits already in milliseconds.
                unit <= 1 ? duration * unit : unit,
            ],
    );
  }

  void _play(String clip, {double scale = 1.0}) {
    final volume = _soundVolume * scale;
    if (volume <= 0) return;
    playClip(clip, volume);
  }

  /// Where a sound actually leaves the app.
  ///
  /// Separated from the decision of *what* to play so a test can watch the
  /// decisions without an audio engine — the bug that prompted this was the
  /// volume slider previewing with the wrong clip, which is a decision, and
  /// invisible from outside until there was a seam here.
  @protected
  @visibleForTesting
  void playClip(String clip, double volume) {
    // Both halves matter. The synchronous throw happens when the platform
    // channel is missing entirely; the rejected future happens when the
    // engine is there but refuses — a browser that has not seen a user
    // gesture yet is the common case, and an unhandled rejection there
    // would surface as a console error on every placement.
    _guard('play $clip', () => FlameAudio.play(clip, volume: volume));
  }

  /// Where a buzz actually leaves the app. The mirror of [playClip].
  @protected
  @visibleForTesting
  void vibrate({
    required int duration,
    required int amplitude,
    List<int>? pattern,
  }) {
    if (_hasVibrator == false) {
      // No motor to drive; the system haptic is better than nothing.
      _guard('haptic fallback', HapticFeedback.mediumImpact);
      return;
    }
    _guard('vibrate', () {
      if (pattern == null) {
        return Vibration.vibrate(duration: duration, amplitude: amplitude);
      }
      return Vibration.vibrate(
        pattern: pattern,
        intensities: [
          for (var i = 0; i < pattern.length; i++) i.isOdd ? amplitude : 0,
        ],
      );
    });
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
