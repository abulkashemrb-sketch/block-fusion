import 'package:flutter_test/flutter_test.dart';

import 'package:block_fusion/services/score_repository.dart';

void main() {
  group('ScoreRepository without a backend', () {
    // Every build runs this path at least once: widget tests never call
    // main(), and a release build whose Supabase.initialize failed keeps
    // running deliberately. None of it may throw — a broken sync must cost
    // the player nothing.
    late ScoreRepository repository;

    setUp(() => repository = ScoreRepository());

    test('reports that it cannot sync', () {
      expect(repository.canSync, isFalse);
    });

    test('returns null rather than zero for the best score', () async {
      // null and 0 mean different things to the caller: null is "no answer"
      // and must not overwrite a best score the player already has.
      expect(await repository.fetchBestScore(), isNull);
    });

    test('reports a failed record instead of throwing', () async {
      expect(await repository.recordScore(120), isFalse);
    });

    test('returns an empty leaderboard instead of throwing', () async {
      expect(await repository.fetchLeaderboard(), isEmpty);
    });
  });
}
