import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:block_fusion/game/block_fusion_game.dart';
import 'package:block_fusion/game/components/clear_burst_component.dart';
import 'package:block_fusion/game/components/floating_text_component.dart';
import 'package:block_fusion/game/components/grid_component.dart';
import 'package:block_fusion/logic/block_generator.dart';
import 'package:block_fusion/logic/game_logic.dart';
import 'package:block_fusion/models/block_color.dart';
import 'package:block_fusion/models/block_shape.dart';
import 'package:block_fusion/models/game_block.dart';
import 'package:block_fusion/models/game_grid.dart';
import 'package:block_fusion/models/grid_position.dart';

class _FixedGenerator extends BlockGenerator {
  _FixedGenerator(this._block);
  final GameBlock _block;

  @override
  GameBlock next() => _block;
}

BlockShape _single() =>
    BlockShape.library.firstWhere((shape) => shape.id == 'single');

void main() {
  /// Pumps a game whose tray is all single cells, then fills row 0 except
  /// for one gap, so a single placement completes a line.
  Future<(GameLogic, BlockFusionGame, GridComponent)> pumpOneAwayFromAClear(
    WidgetTester tester, {
    BlockColor rowColor = BlockColor.green,
    BlockColor pieceColor = BlockColor.red,
  }) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final logic = GameLogic(
      generator: _FixedGenerator(
        GameBlock(shape: _single(), color: pieceColor),
      ),
    );
    for (var col = 1; col < GameGrid.size; col++) {
      logic.grid.place(_single(), GridPosition(0, col), rowColor);
    }

    final game = BlockFusionGame(logic: logic);
    await tester.pumpWidget(MaterialApp(home: GameWidget(game: game)));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));

    final grid = game.children.whereType<GridComponent>().first;
    return (logic, game, grid);
  }

  testWidgets('clearing a line spawns a burst for every cleared cell',
      (tester) async {
    final (logic, _, grid) = await pumpOneAwayFromAClear(tester);

    expect(grid.children.whereType<ClearBurstComponent>(), isEmpty);

    logic.tryPlace(0, const GridPosition(0, 0));
    await tester.pump();

    // One burst per cell of the completed row — the placed cell included,
    // because it was filled and then cleared in the same move.
    expect(
      grid.children.whereType<ClearBurstComponent>().length,
      GameGrid.size,
    );
  });

  testWidgets('a burst is short-lived and cleans itself up', (tester) async {
    final (logic, _, grid) = await pumpOneAwayFromAClear(tester);

    logic.tryPlace(0, const GridPosition(0, 0));
    await tester.pump();
    expect(grid.children.whereType<ClearBurstComponent>(), isNotEmpty);

    // Long enough for the animation to finish; an effect that outlives its
    // animation would pile up one leak per clear for the whole game.
    await tester.pump(const Duration(seconds: 2));
    await tester.pump();

    expect(grid.children.whereType<ClearBurstComponent>(), isEmpty);
  });

  testWidgets('a placement that clears nothing spawns no effects',
      (tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final logic = GameLogic(
      generator: _FixedGenerator(
        GameBlock(shape: _single(), color: BlockColor.blue),
      ),
    );
    final game = BlockFusionGame(logic: logic);
    await tester.pumpWidget(MaterialApp(home: GameWidget(game: game)));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));
    final grid = game.children.whereType<GridComponent>().first;

    logic.tryPlace(0, const GridPosition(4, 4));
    await tester.pump();

    expect(grid.children.whereType<ClearBurstComponent>(), isEmpty);
    expect(grid.children.whereType<FloatingTextComponent>(), isEmpty);
  });

  testWidgets('a clear shows the points gained', (tester) async {
    // Two colours in the row, so this scores the plain total and not the
    // same-colour bonus — it is the "+N" label under test, not the rule.
    final (logic, _, grid) = await pumpOneAwayFromAClear(tester);

    logic.tryPlace(0, const GridPosition(0, 0));
    await tester.pump();

    final labels =
        grid.children.whereType<FloatingTextComponent>().map((l) => l.text);
    expect(labels, contains('+${logic.lastMove!.pointsGained}'));
  });

  testWidgets('a single-colour line is called out', (tester) async {
    final (logic, _, grid) = await pumpOneAwayFromAClear(
      tester,
      rowColor: BlockColor.green,
      pieceColor: BlockColor.green,
    );

    logic.tryPlace(0, const GridPosition(0, 0));
    await tester.pump();

    final labels =
        grid.children.whereType<FloatingTextComponent>().map((l) => l.text);
    expect(labels, contains('SAME COLOUR!'));
  });

  testWidgets('a notification that is not a move replays nothing',
      (tester) async {
    // GameLogic notifies for things other than placements — a stored best
    // score arriving from the server does. Replaying the last move's
    // effects then would burst the same cells a second time.
    final (logic, _, grid) = await pumpOneAwayFromAClear(tester);

    logic.tryPlace(0, const GridPosition(0, 0));
    await tester.pump();
    final afterMove = grid.children.whereType<ClearBurstComponent>().length;
    expect(afterMove, greaterThan(0));

    logic.raiseBestScore(99999);
    await tester.pump();

    expect(grid.children.whereType<ClearBurstComponent>().length, afterMove);
  });

  testWidgets('beating the best score is celebrated', (tester) async {
    final (logic, _, grid) = await pumpOneAwayFromAClear(tester);

    logic.tryPlace(0, const GridPosition(0, 0));
    await tester.pump();

    final labels =
        grid.children.whereType<FloatingTextComponent>().map((l) => l.text);
    expect(labels, contains('NEW BEST!'));
  });
}
