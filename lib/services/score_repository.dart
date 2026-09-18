import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/leaderboard_entry.dart';
import 'supabase_config.dart';

/// Reads and writes the player's scores.
///
/// Every method returns a usable value rather than throwing when there is no
/// backend, no session, or no network: score sync is a bonus on top of the
/// game, and a failed sync must never cost the player their run. Failures
/// are logged in debug and swallowed in release.
class ScoreRepository {
  ScoreRepository({SupabaseClient? client})
      : _client = client ?? SupabaseConfig.maybeClient;

  final SupabaseClient? _client;

  String? get _userId => _client?.auth.currentUser?.id;

  /// Whether there is both a backend and a signed-in player to sync for.
  bool get canSync => _client != null && _userId != null;

  /// The player's best score as the server knows it, or `null` when there is
  /// nothing to read — not signed in, no backend, or the request failed.
  ///
  /// `null` and `0` mean different things to the caller: `null` is "no
  /// answer", and must not overwrite a local best score.
  Future<int?> fetchBestScore() async {
    final client = _client;
    final userId = _userId;
    if (client == null || userId == null) return null;

    try {
      final row = await client
          .from('profiles')
          .select('best_score')
          .eq('id', userId)
          .maybeSingle();
      final value = row?['best_score'];
      return value is int ? value : null;
    } catch (error) {
      _log('fetchBestScore', error);
      return null;
    }
  }

  /// Records one finished game. Returns whether it reached the server.
  ///
  /// The profile's best score is updated by a database trigger, not here, so
  /// a client cannot claim a best score it never played and a retried
  /// request cannot lower one that already stands.
  Future<bool> recordScore(int score) async {
    final client = _client;
    final userId = _userId;
    if (client == null || userId == null || score <= 0) return false;

    try {
      await client.from('scores').insert({
        'user_id': userId,
        'score': score,
      });
      return true;
    } catch (error) {
      _log('recordScore', error);
      return false;
    }
  }

  /// The top players by best score. Empty when unavailable.
  Future<List<LeaderboardEntry>> fetchLeaderboard({int limit = 20}) async {
    final client = _client;
    if (client == null) return const [];

    try {
      final rows = await client
          .from('profiles')
          .select('id, display_name, avatar_url, best_score')
          .order('best_score', ascending: false)
          .limit(limit);
      return [
        for (final row in rows)
          LeaderboardEntry.fromRow(Map<String, dynamic>.from(row)),
      ];
    } catch (error) {
      _log('fetchLeaderboard', error);
      return const [];
    }
  }

  void _log(String operation, Object error) {
    if (kDebugMode) {
      debugPrint('ScoreRepository.$operation failed: $error');
    }
  }
}
