/// One row of the leaderboard: a player and the best score they have
/// recorded.
///
/// Plain data with no Supabase types in it, so the leaderboard widget and
/// its tests do not need a backend to exist.
class LeaderboardEntry {
  const LeaderboardEntry({
    required this.userId,
    required this.displayName,
    required this.bestScore,
    this.avatarUrl,
  });

  /// Builds an entry from a `profiles` row.
  ///
  /// The row is whatever the database returned, so every field is treated as
  /// possibly missing or the wrong type rather than cast blindly — a player
  /// who signed in without a name should not break the whole list.
  factory LeaderboardEntry.fromRow(Map<String, dynamic> row) {
    final name = row['display_name'];
    final score = row['best_score'];
    return LeaderboardEntry(
      userId: row['id'] as String? ?? '',
      displayName: name is String && name.isNotEmpty ? name : 'Player',
      bestScore: score is int ? score : 0,
      avatarUrl: row['avatar_url'] as String?,
    );
  }

  final String userId;
  final String displayName;
  final int bestScore;
  final String? avatarUrl;
}
