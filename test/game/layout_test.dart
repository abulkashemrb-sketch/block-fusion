import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:block_fusion/game/block_fusion_game.dart';
import 'package:block_fusion/game/components/block_piece_component.dart';
import 'package:block_fusion/game/components/grid_component.dart';
import 'package:block_fusion/logic/game_logic.dart';
import 'package:block_fusion/models/game_grid.dart';

/// The board and tray have to stay on screen and stay apart on every
/// surface the game can run on — a tall phone, a short landscape window, a
/// tablet. The web build in particular can be resized to anything.
void main() {
  Future<(GridComponent, BlockFusionGame)> pumpAt(
    WidgetTester tester,
    Size size,
  ) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final game = BlockFusionGame(logic: GameLogic());
    await tester.pumpWidget(MaterialApp(home: GameWidget(game: game)));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));

    return (game.children.whereType<GridComponent>().first, game);
  }

  const surfaces = <String, Size>{
    'tall phone': Size(390, 844),
    'short phone': Size(360, 640),
    'tablet portrait': Size(768, 1024),
    'landscape': Size(900, 500),
    'very wide': Size(1400, 700),
  };

  for (final entry in surfaces.entries) {
    testWidgets('the board fits on a ${entry.key}', (tester) async {
      final (grid, _) = await pumpAt(tester, entry.value);

      expect(grid.cellSize, greaterThan(0));
      expect(grid.position.x, greaterThanOrEqualTo(0));
      expect(grid.position.y, greaterThanOrEqualTo(0));
      expect(grid.position.x + grid.size.x,
          lessThanOrEqualTo(entry.value.width + 0.01));
      expect(grid.position.y + grid.size.y,
          lessThanOrEqualTo(entry.value.height + 0.01));
      // closeTo, not equals: the two are computed by different float
      // paths and land a ten-thousandth apart.
      expect(grid.size.x, closeTo(grid.cellSize * GameGrid.size, 0.01));
    });

    testWidgets('the tray sits below the board on a ${entry.key}',
        (tester) async {
      final (grid, game) = await pumpAt(tester, entry.value);

      // The whole point of laying them out together: on a short landscape
      // window the tray used to overlap the board.
      expect(grid.trayCenterY, greaterThan(grid.position.y + grid.size.y));
      expect(grid.trayCenterY, lessThan(entry.value.height));

      for (final piece in game.children.whereType<BlockPieceComponent>()) {
        expect(piece.position.y, greaterThan(grid.position.y + grid.size.y),
            reason: 'a tray piece overlapped the board');
        expect(piece.position.x, greaterThanOrEqualTo(0));
        expect(piece.position.x + piece.size.x,
            lessThanOrEqualTo(entry.value.width + 0.01));
      }
    });
  }
}
