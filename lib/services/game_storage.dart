import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/game_snapshot.dart';
import 'feedback_service.dart';

/// Keeps the game in progress on the device.
///
/// Losing a run because a call came in is not a missing feature, it reads as
/// a broken game — so the board, the tray and the score are written after
/// every move and read back on launch.
///
/// Also carries the best score, which used to live only in memory: a player
/// with no account still deserves to keep their record.
///
/// Storage is best-effort throughout. A device that refuses to write, a
/// browser with storage blocked, a save from an older version — all of them
/// mean "start fresh", never "fail to launch".
class GameStorage {
  /// [preferences] is injectable so tests can hand in an in-memory store
  /// instead of reaching for a platform plugin.
  GameStorage({SharedPreferences? preferences}) : _cached = preferences;

  static const String _snapshotKey = 'block_fusion.snapshot';
  static const String _bestScoreKey = 'block_fusion.bestScore';
  // The first release stored these as on/off booleans. They are still read
  // so a player who had muted the game stays muted after the update.
  static const String _soundOnKey = 'block_fusion.sound';
  static const String _hapticsOnKey = 'block_fusion.haptics';
  static const String _volumeKey = 'block_fusion.soundVolume';
  static const String _strengthKey = 'block_fusion.hapticStrength';

  /// Opened lazily and kept, so every save after the first is one write
  /// rather than a plugin round trip.
  SharedPreferences? _cached;

  Future<SharedPreferences?> _prefs() async {
    final existing = _cached;
    if (existing != null) return existing;
    try {
      return _cached = await SharedPreferences.getInstance();
    } catch (error) {
      _log('open', error);
      return null;
    }
  }

  /// The saved game, or `null` when there is none to resume.
  Future<GameSnapshot?> loadGame() async {
    final prefs = await _prefs();
    final raw = prefs?.getString(_snapshotKey);
    if (raw == null) return null;

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return null;
      return GameSnapshot.fromJson(decoded);
    } catch (error) {
      // A truncated or foreign save is not worth keeping around to fail
      // again on every launch.
      _log('loadGame', error);
      await clearGame();
      return null;
    }
  }

  Future<void> saveGame(GameSnapshot snapshot) async {
    final prefs = await _prefs();
    if (prefs == null) return;
    try {
      await prefs.setString(_snapshotKey, jsonEncode(snapshot.toJson()));
      await prefs.setInt(_bestScoreKey, snapshot.bestScore);
    } catch (error) {
      _log('saveGame', error);
    }
  }

  /// Forgets the game in progress, keeping the best score. Called when a
  /// run ends, so the next launch starts clean instead of resuming a board
  /// that is already game over.
  Future<void> clearGame() async {
    final prefs = await _prefs();
    try {
      await prefs?.remove(_snapshotKey);
    } catch (error) {
      _log('clearGame', error);
    }
  }

  Future<int> loadBestScore() async {
    final prefs = await _prefs();
    try {
      return prefs?.getInt(_bestScoreKey) ?? 0;
    } catch (error) {
      _log('loadBestScore', error);
      return 0;
    }
  }

  Future<void> saveBestScore(int value) async {
    final prefs = await _prefs();
    if (prefs == null) return;
    try {
      await prefs.setInt(_bestScoreKey, value);
    } catch (error) {
      _log('saveBestScore', error);
    }
  }

  /// How loud and how hard the player wants the game, defaulting to the
  /// service's own defaults for someone who has never opened settings.
  ///
  /// Falls back to the booleans the first release wrote, so an update does
  /// not silently unmute a game somebody muted.
  Future<({double volume, HapticStrength strength})>
      loadFeedbackSettings() async {
    final prefs = await _prefs();
    try {
      final volume = prefs?.getDouble(_volumeKey) ??
          ((prefs?.getBool(_soundOnKey) ?? true)
              ? FeedbackService.defaultVolume
              : 0.0);
      final strength = prefs?.getString(_strengthKey) != null
          ? HapticStrength.fromName(prefs!.getString(_strengthKey))
          : ((prefs?.getBool(_hapticsOnKey) ?? true)
              ? HapticStrength.medium
              : HapticStrength.off);
      return (volume: volume.clamp(0.0, 1.0), strength: strength);
    } catch (error) {
      _log('loadFeedbackSettings', error);
      return (
        volume: FeedbackService.defaultVolume,
        strength: HapticStrength.medium,
      );
    }
  }

  Future<void> saveFeedbackSettings({
    required double volume,
    required HapticStrength strength,
  }) async {
    final prefs = await _prefs();
    if (prefs == null) return;
    try {
      await prefs.setDouble(_volumeKey, volume);
      await prefs.setString(_strengthKey, strength.name);
    } catch (error) {
      _log('saveFeedbackSettings', error);
    }
  }

  void _log(String what, Object error) {
    if (kDebugMode) debugPrint('GameStorage.$what failed: $error');
  }
}
