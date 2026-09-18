import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:block_fusion/game/block_fusion_game.dart';
import 'package:block_fusion/game/components/block_piece_component.dart';
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

/// The layout formulas of GridComponent / TrayController / BlockPieceComponent
/// recomputed for a fixed canvas, so a drag test can aim at real coordinates.
///
/// Duplicating this arithmetic is the point: change the layout without
/// thinking and these coordinates stop landing where they should, loudly.
class _Layout {
  _Layout(this.canvasWidth, this.canvasHeight);

  final double canvasWidth;
  final double canvasHeight;

  static const int gridSize = 8;
  static const double trayScale = 0.72;
  static const double fingerLift = 1.2;
  static const double hudBand = 0.13;
  static const double trayBandCells = 4 * trayScale + 0.25;
  static const double boardToTrayGapCells = 0.6;

  double get cellSize {
    final maxWidth = canvasWidth - 20;
    final maxHeight = canvasHeight * 0.55;
    return (maxWidth < maxHeight ? maxWidth : maxHeight) / gridSize;
  }

  double get trayCellSize => cellSize * trayScale;

  double get _boardTop {
    final slack = canvasHeight -
        canvasHeight * hudBand -
        cellSize * gridSize -
        cellSize * boardToTrayGapCells -
        cellSize * trayBandCells;
    return canvasHeight * hudBand + (slack > 0 ? slack / 2 : 0);
  }

  Offset get gridTopLeft =>
      Offset((canvasWidth - cellSize * gridSize) / 2, _boardTop);

  double get trayCenterY =>
      _boardTop +
      cellSize * gridSize +
      cellSize * boardToTrayGapCells +
      cellSize * trayBandCells / 2;

  /// Top-left of the piece resting in tray slot [index], for a shape of
  /// [width] x [height] cells.
  Offset trayHome(int index, {int width = 1, int height = 1}) {
    final slotWidth = canvasWidth / 3;
    final slotCenterX = slotWidth * index + slotWidth / 2;
    return Offset(
      slotCenterX - width * trayCellSize / 2,
      trayCenterY - height * trayCellSize / 2,
    );
  }

  /// Where the piece's top-left sits the instant a drag starts from the
  /// center of its tray rest position: grown from tray scale to board scale
  /// around the grab point, then lifted clear of the finger.
  Offset draggedTopLeft(Offset trayHome, {int width = 1, int height = 1}) {
    final growth = Offset(
      width * (cellSize - trayCellSize),
      height * (cellSize - trayCellSize),
    );
    return trayHome - growth / 2 - Offset(0, cellSize * fingerLift);
  }
}

void main() {
  const canvasSize = Size(400, 800);
  final layout = _Layout(canvasSize.width, canvasSize.height);

  Future<(GameLogic, BlockFusionGame)> pumpGame(WidgetTester tester) async {
    tester.view.physicalSize = canvasSize;
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
    return (logic, game);
  }

  testWidgets(
    'dragging a tray piece onto the board places it and scores a point',
    (tester) async {
      final (logic, _) = await pumpGame(tester);

      final home = layout.trayHome(0);
      final grabPoint = home + Offset(layout.trayCellSize / 2, layout.trayCellSize / 2);
      final dropDelta = layout.gridTopLeft - layout.draggedTopLeft(home);

      expect(logic.score, 0);

      final gesture = await tester.startGesture(grabPoint);
      await tester.pump();
      await gesture.moveTo(grabPoint + dropDelta);
      await tester.pump();
      await gesture.up();
      await tester.pump();

      expect(logic.score, 1);
      expect(logic.grid.cellAt(const GridPosition(0, 0)).isFilled, isTrue);
    },
  );

  testWidgets(
    'a dragged piece is drawn at board scale and held clear of the finger',
    (tester) async {
      final (_, game) = await pumpGame(tester);

      final home = layout.trayHome(0);
      final grabPoint = home + Offset(layout.trayCellSize / 2, layout.trayCellSize / 2);

      final piece = game.children.whereType<BlockPieceComponent>().first;
      expect(piece.size.x, closeTo(layout.trayCellSize, 0.01));

      final gesture = await tester.startGesture(grabPoint);
      await tester.pump();
      await gesture.moveTo(grabPoint + const Offset(0, -40));
      await tester.pump();

      // Drawn at one board cell per shape cell: anything else and the piece
      // under the finger would not cover the cells the preview highlights.
      expect(piece.size.x, closeTo(layout.cellSize, 0.01));
      expect(piece.size.y, closeTo(layout.cellSize, 0.01));

      // And lifted above the pointer, which would otherwise cover it.
      expect(piece.position.y + piece.size.y, lessThan(grabPoint.dy - 40));

      await gesture.up();
      await tester.pump();
    },
  );

  testWidgets(
    'a cancelled drag returns the piece to its tray size and slot',
    (tester) async {
      final (logic, game) = await pumpGame(tester);

      final home = layout.trayHome(0);
      final grabPoint = home + Offset(layout.trayCellSize / 2, layout.trayCellSize / 2);
      final piece = game.children.whereType<BlockPieceComponent>().first;

      final gesture = await tester.startGesture(grabPoint);
      await tester.pump();
      // Drop far off the board, where no placement is possible.
      await gesture.moveTo(const Offset(2, 2));
      await tester.pump();
      await gesture.up();
      await tester.pump();

      expect(logic.score, 0);
      expect(piece.size.x, closeTo(layout.trayCellSize, 0.01));
      expect(piece.position.x, closeTo(home.dx, 0.01));
      expect(piece.position.y, closeTo(home.dy, 0.01));
    },
  );
}
