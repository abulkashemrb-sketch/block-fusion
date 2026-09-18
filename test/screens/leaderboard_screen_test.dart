import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:block_fusion/models/leaderboard_entry.dart';
import 'package:block_fusion/screens/leaderboard_screen.dart';
import 'package:block_fusion/services/score_repository.dart';
import 'package:block_fusion/theme/app_theme.dart';

/// Serves a fixed table one page at a time, and records what was asked for.
class _FakeRepository extends ScoreRepository {
  _FakeRepository(this.total);

  final int total;
  final List<({int limit, int offset})> requests = [];

  @override
  Future<List<LeaderboardEntry>> fetchLeaderboard({
    int limit = 20,
    int offset = 0,
  }) async {
    requests.add((limit: limit, offset: offset));
    return [
      for (var i = offset; i < (offset + limit).clamp(0, total); i++)
        LeaderboardEntry(
          userId: 'user-$i',
          displayName: 'Player $i',
          bestScore: total - i,
        ),
    ];
  }
}

void main() {
  Future<_FakeRepository> pump(WidgetTester tester, int total,
      {String? currentUserId}) async {
    final repository = _FakeRepository(total);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: LeaderboardScreen(
          repository: repository,
          currentUserId: currentUserId,
        ),
      ),
    );
    await tester.pumpAndSettle();
    return repository;
  }

  testWidgets('an empty table explains itself', (tester) async {
    await pump(tester, 0);

    expect(find.textContaining('No scores yet'), findsOneWidget);
  });

  testWidgets('the first page is one request for 20 rows', (tester) async {
    final repository = await pump(tester, 50);

    expect(repository.requests, hasLength(1));
    expect(repository.requests.single.limit, 20);
    expect(repository.requests.single.offset, 0);
    expect(find.text('Player 0'), findsOneWidget);
  });

  testWidgets('a full page offers more', (tester) async {
    await pump(tester, 50);

    // Twenty rows do not fit on one screen, and a ListView does not build
    // what it cannot show — so scroll to the end the way a player would.
    await tester.scrollUntilVisible(find.text('Load more'), 300);

    expect(find.text('Load more'), findsOneWidget);
  });

  testWidgets('a short page does not', (tester) async {
    // Fewer rows than a page means the table ended — asking again would
    // only ever return nothing.
    await pump(tester, 7);

    expect(find.text('Load more'), findsNothing);
  });

  testWidgets('loading more asks for the next page and appends it',
      (tester) async {
    final repository = await pump(tester, 50);

    await tester.scrollUntilVisible(find.text('Load more'), 200);
    await tester.tap(find.text('Load more'));
    await tester.pumpAndSettle();

    expect(repository.requests, hasLength(2));
    expect(repository.requests.last.offset, 20);
    // The first page is still there; the second was added, not swapped in.
    await tester.scrollUntilVisible(find.text('Player 20'), 200);
    expect(find.text('Player 20'), findsOneWidget);
  });

  testWidgets('refreshing starts over from the first page', (tester) async {
    final repository = await pump(tester, 50);
    await tester.scrollUntilVisible(find.text('Load more'), 200);
    await tester.tap(find.text('Load more'));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.refresh));
    await tester.pumpAndSettle();

    expect(repository.requests.last.offset, 0);
    // Back to a single page, so the end button is within one screen of the
    // top again — which it would not be if the second page had survived.
    await tester.scrollUntilVisible(find.text('Load more'), 300);
    expect(find.text('Player 20'), findsNothing);
  });
}
