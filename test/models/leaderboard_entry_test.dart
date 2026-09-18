import 'package:flutter_test/flutter_test.dart';

import 'package:block_fusion/models/leaderboard_entry.dart';

void main() {
  group('LeaderboardEntry.fromRow', () {
    test('reads a complete row', () {
      final entry = LeaderboardEntry.fromRow({
        'id': 'user-1',
        'display_name': 'Kashem',
        'avatar_url': 'https://example.com/a.png',
        'best_score': 420,
      });

      expect(entry.userId, 'user-1');
      expect(entry.displayName, 'Kashem');
      expect(entry.avatarUrl, 'https://example.com/a.png');
      expect(entry.bestScore, 420);
    });

    test('falls back to a placeholder name when the row has none', () {
      // A player can reach the table without Google having given us a name,
      // and one such row must not blank out the whole leaderboard.
      final missing = LeaderboardEntry.fromRow({
        'id': 'user-2',
        'best_score': 10,
      });
      final empty = LeaderboardEntry.fromRow({
        'id': 'user-3',
        'display_name': '',
        'best_score': 10,
      });

      expect(missing.displayName, 'Player');
      expect(empty.displayName, 'Player');
    });

    test('treats a missing or non-integer score as zero', () {
      final missing = LeaderboardEntry.fromRow({'id': 'user-4'});
      final wrongType =
          LeaderboardEntry.fromRow({'id': 'user-5', 'best_score': '99'});

      expect(missing.bestScore, 0);
      expect(wrongType.bestScore, 0);
    });

    test('survives a row with no id at all', () {
      final entry = LeaderboardEntry.fromRow(const {});

      expect(entry.userId, '');
      expect(entry.displayName, 'Player');
      expect(entry.bestScore, 0);
      expect(entry.avatarUrl, isNull);
    });
  });
}
