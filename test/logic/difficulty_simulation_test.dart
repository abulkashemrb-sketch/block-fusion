@Tags(['simulation'])
library;

import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:block_fusion/logic/block_generator.dart';
import 'package:block_fusion/logic/game_logic.dart';
import 'package:block_fusion/models/game_block.dart';
import 'package:block_fusion/models/game_grid.dart';
import 'package:block_fusion/models/grid_position.dart';

/// Measures how long a game lasts, so difficulty is tuned against numbers
/// rather than a hunch.
///
/// Skipped by a normal `flutter test` run — see `dart_test.yaml`. It plays
/// hundreds of full games and takes minutes, and it asserts loose bounds
/// rather than exact values: it is a measuring instrument, not a regression
/// test. Run it with:
///
///     flutter test --run-skipped --tags simulation
///
/// The player it simulates is deliberately mediocre: it takes the placement
/// that clears the most lines, and otherwise the one that leaves the fewest
/// isolated single-cell gaps. A good human does better; someone playing on
/// a bus does about this well.
({double moves, double score, double p10, double p90}) simulate({
  required int games,
  int seed = 1,
  double? crowdingBias,
}) {
  final random = Random(seed);
  final moveCounts = <int>[];
  final scores = <int>[];

  for (var game = 0; game < games; game++) {
    final seedForGame = random.nextInt(1 << 32);
    final logic = GameLogic(
      random: Random(seedForGame),
      generator: BlockGenerator(
        random: Random(seedForGame ^ 0x5bf03635),
        crowdingBias: crowdingBias,
      ),
    );
    var moves = 0;

    while (!logic.isGameOver && moves < 2000) {
      final choice = _bestMove(logic);
      if (choice == null) break;
      logic.tryPlace(choice.$1, choice.$2);
      moves++;
    }
    moveCounts.add(moves);
    scores.add(logic.score);
  }

  moveCounts.sort();
  return (
    moves: moveCounts.reduce((a, b) => a + b) / games,
    score: scores.reduce((a, b) => a + b) / games,
    p10: moveCounts[(games * 0.1).floor()].toDouble(),
    p90: moveCounts[(games * 0.9).floor()].toDouble(),
  );
}

/// The tray slot and origin this simulated player would choose.
(int, GridPosition)? _bestMove(GameLogic logic) {
  (int, GridPosition)? best;
  var bestScore = -1 << 30;

  for (var slot = 0; slot < logic.tray.length; slot++) {
    final block = logic.tray[slot];
    if (block == null) continue;

    for (var row = 0; row < GameGrid.size; row++) {
      for (var col = 0; col < GameGrid.size; col++) {
        final origin = GridPosition(row, col);
        if (!logic.canPlace(block, origin)) continue;
        if (!_fits(logic, block, origin)) continue;

        final value = _valueOf(logic, block, origin);
        if (value > bestScore) {
          bestScore = value;
          best = (slot, origin);
        }
      }
    }
  }
  return best;
}

bool _fits(GameLogic logic, GameBlock block, GridPosition origin) {
  for (final offset in block.shape.cells) {
    if (!logic.grid.isInBounds(origin + offset)) return false;
  }
  return true;
}

/// Lines completed are worth far more than tidiness, but tidiness breaks
/// the ties — which is roughly how a casual player thinks.
int _valueOf(GameLogic logic, GameBlock block, GridPosition origin) {
  final occupied = {
    for (final offset in block.shape.cells) origin + offset,
  };
  bool filled(GridPosition p) =>
      occupied.contains(p) || logic.grid.cellAt(p).isFilled;

  var lines = 0;
  for (var row = 0; row < GameGrid.size; row++) {
    if (List.generate(GameGrid.size, (c) => GridPosition(row, c)).every(filled)) {
      lines++;
    }
  }
  for (var col = 0; col < GameGrid.size; col++) {
    if (List.generate(GameGrid.size, (r) => GridPosition(r, col)).every(filled)) {
      lines++;
    }
  }

  var holes = 0;
  for (var row = 0; row < GameGrid.size; row++) {
    for (var col = 0; col < GameGrid.size; col++) {
      final p = GridPosition(row, col);
      if (filled(p)) continue;
      final neighbours = [
        GridPosition(row - 1, col),
        GridPosition(row + 1, col),
        GridPosition(row, col - 1),
        GridPosition(row, col + 1),
      ].where(logic.grid.isInBounds);
      if (neighbours.every(filled)) holes++;
    }
  }

  return lines * 100 - holes * 5;
}

void main() {
  test('sweep the crowding bias', () {
    // ignore: avoid_print
    print('\n  bias   moves   p10   p90   score');
    for (final bias in [0.0, 1.0, 1.5, 2.0, 2.5, 3.0]) {
      final r = simulate(games: 150, crowdingBias: bias);
      // ignore: avoid_print
      print('  ${bias.toStringAsFixed(1)}   '
          '${r.moves.toStringAsFixed(0).padLeft(5)} '
          '${r.p10.toStringAsFixed(0).padLeft(5)} '
          '${r.p90.toStringAsFixed(0).padLeft(5)} '
          '${r.score.toStringAsFixed(0).padLeft(7)}');
    }
    // ignore: avoid_print
    print('');
  });

  test('the shipped setting keeps a casual game going', () {
    final result = simulate(games: 300);

    // ignore: avoid_print
    print('\n  shipped: ${result.moves.toStringAsFixed(0)} moves, '
        'p10 ${result.p10.toStringAsFixed(0)}, '
        'score ${result.score.toStringAsFixed(0)}\n');

    // Forgiving enough that a bad run is not over in a minute, and not so
    // forgiving that a game never ends. Both bounds are wide: this guards
    // against a change that moves difficulty by a lot, not against the
    // noise of a few hundred simulated games.
    expect(result.moves, greaterThan(100));
    expect(result.moves, lessThan(400));
    expect(result.p10, greaterThan(40));
  });
}
