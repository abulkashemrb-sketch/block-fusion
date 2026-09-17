import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:block_fusion/game/block_fusion_game.dart';
import 'package:block_fusion/logic/block_generator.dart';
import 'package:block_fusion/logic/game_logic.dart';
import 'package:block_fusion/models/block_color.dart';
import 'package:block_fusion/models/block_shape.dart';
import 'package:block_fusion/models/game_block.dart';
import 'package:block_fusion/models/grid_position.dart';

class _FixedGenerator extends BlockGenerator {
  _FixedGenerator(this._blocks);
  final List<GameBlock> _blocks;
  int _index = 0;

  @override
  GameBlock next() => _blocks[_index++ % _blocks.length];
}

void main() {
  testWidgets(
    'dragging a tray piece onto the board places it and scores a point',
    (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final single = GameBlock(
        shape: BlockShape.library.firstWhere((s) => s.id == 'single'),
        color: BlockColor.red,
      );
      final logic = GameLogic(generator: _FixedGenerator([single, single, single]));
      final game = BlockFusionGame(logic: logic);

      await tester.pumpWidget(MaterialApp(home: GameWidget(game: game)));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 16));

      // Reproduce the same layout formulas as GridComponent/TrayController
      // for a 400x800 canvas, so this test proves the real drag pipeline
      // (not just the pure logic layer already covered by game_logic_test).
      const canvasWidth = 400.0;
      const canvasHeight = 800.0;
      const gridSize = 8;
      final cellSize = ((canvasWidth - 32) < (canvasHeight * 0.55)
              ? (canvasWidth - 32)
              : (canvasHeight * 0.55)) /
          gridSize;
      final gridPosition = Offset(
        (canvasWidth - cellSize * gridSize) / 2,
        canvasHeight * 0.12,
      );

      final pieceCellSize = cellSize * 0.65;
      const slotWidth = canvasWidth / 3;
      const trayCenterY = canvasHeight * 0.8;
      final slot0CenterX = slotWidth / 2;
      final home0 = Offset(
        slot0CenterX - pieceCellSize / 2,
        trayCenterY - pieceCellSize / 2,
      );
      final dragStart = home0 + Offset(pieceCellSize / 2, pieceCellSize / 2);
      final dropDelta = gridPosition - home0; // lands the piece at cell (0, 0)

      expect(logic.score, 0);

      final gesture = await tester.startGesture(dragStart);
      await tester.pump();
      await gesture.moveTo(dragStart + dropDelta);
      await tester.pump();
      await gesture.up();
      await tester.pump();

      expect(logic.score, 1);
      expect(logic.grid.cellAt(const GridPosition(0, 0)).isFilled, isTrue);
    },
  );
}
