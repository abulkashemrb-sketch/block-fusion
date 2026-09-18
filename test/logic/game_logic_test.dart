import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import 'package:block_fusion/logic/block_generator.dart';
import 'package:block_fusion/logic/game_logic.dart';
import 'package:block_fusion/models/block_color.dart';
import 'package:block_fusion/models/block_shape.dart';
import 'package:block_fusion/models/game_block.dart';
import 'package:block_fusion/models/game_grid.dart';
import 'package:block_fusion/models/grid_position.dart';

/// Hands out a fixed, repeating sequence of blocks instead of random ones,
/// so tests can place pieces at exact, predictable positions.
class _FixedGenerator extends BlockGenerator {
  _FixedGenerator(this._blocks);

  final List<GameBlock> _blocks;
  int _index = 0;

  @override
  GameBlock next() => _blocks[_index++ % _blocks.length];
}

BlockShape _shapeById(String id) =>
    BlockShape.library.firstWhere((shape) => shape.id == id);

void main() {
  group('GameLogic', () {
    test('placing a block increases score by its cell count', () {
      final single = GameBlock(shape: _shapeById('single'), color: BlockColor.red);
      final logic = GameLogic(generator: _FixedGenerator([single, single, single]));

      final placed = logic.tryPlace(0, const GridPosition(0, 0));

      expect(placed, isTrue);
      expect(logic.score, 1);
      expect(logic.grid.cellAt(const GridPosition(0, 0)).isFilled, isTrue);
    });

    test('rejects placement on an already-filled cell', () {
      final single = GameBlock(shape: _shapeById('single'), color: BlockColor.blue);
      final logic = GameLogic(generator: _FixedGenerator([single, single, single]));

      logic.tryPlace(0, const GridPosition(0, 0));
      final placedAgain = logic.tryPlace(1, const GridPosition(0, 0));

      expect(placedAgain, isFalse);
      expect(logic.score, 1);
    });

    test('clearing a full row awards the line-clear bonus on top of placement points', () {
      // Deliberately two colors: a single-color row would also earn the
      // same-color bonus, which is covered by its own test below.
      final greenQuad =
          GameBlock(shape: _shapeById('tetra_i_h'), color: BlockColor.green);
      final blueQuad =
          GameBlock(shape: _shapeById('tetra_i_h'), color: BlockColor.blue);
      final filler = GameBlock(shape: _shapeById('domino_h'), color: BlockColor.yellow);
      final logic =
          GameLogic(generator: _FixedGenerator([greenQuad, blueQuad, filler]));

      logic.tryPlace(0, const GridPosition(0, 0)); // fills columns 0-3
      final scoreBeforeClear = logic.score;
      logic.tryPlace(1, const GridPosition(0, 4)); // fills columns 4-7 -> row complete

      expect(logic.score, scoreBeforeClear + 4 + 10);
      expect(logic.grid.cellAt(const GridPosition(0, 0)).isEmpty, isTrue);
    });

    test('refills the tray once all three pieces have been placed', () {
      final single = GameBlock(shape: _shapeById('single'), color: BlockColor.purple);
      final logic = GameLogic(
        generator: _FixedGenerator([single, single, single, single]),
      );

      logic.tryPlace(0, const GridPosition(0, 0));
      logic.tryPlace(1, const GridPosition(0, 1));
      logic.tryPlace(2, const GridPosition(0, 2));

      expect(logic.tray.every((block) => block != null), isTrue);
    });

    test('restart clears the board, score, and game-over flag', () {
      final single = GameBlock(shape: _shapeById('single'), color: BlockColor.orange);
      final logic = GameLogic(generator: _FixedGenerator([single, single, single]));

      logic.tryPlace(0, const GridPosition(0, 0));
      logic.restart();

      expect(logic.score, 0);
      expect(logic.isGameOver, isFalse);
      expect(logic.grid.cellAt(const GridPosition(0, 0)).isEmpty, isTrue);

      // Placing again after a restart must not crash (regression check for
      // the tray list needing to stay nullable after being reassigned).
      final placedAfterRestart = logic.tryPlace(0, const GridPosition(1, 1));
      expect(placedAfterRestart, isTrue);
    });

    test('a locked cell blocks placement but chips down when its line clears', () {
      final single = GameBlock(shape: _shapeById('single'), color: BlockColor.teal);
      final logic = GameLogic(generator: _FixedGenerator([single]));

      logic.grid.lockCell(const GridPosition(0, 5));
      expect(
        logic.grid.canPlace(_shapeById('single'), const GridPosition(0, 5)),
        isFalse,
      );

      for (final col in [0, 1, 2, 3, 4, 6, 7]) {
        final trayIndex = logic.tray.indexWhere((block) => block != null);
        logic.tryPlace(trayIndex, GridPosition(0, col));
      }

      final lockedCell = logic.grid.cellAt(const GridPosition(0, 5));
      expect(lockedCell.isLocked, isTrue);
      expect(lockedCell.lockLevel, 1);
    });

    test('a locked cell fully unlocks after being crossed by two line clears', () {
      final single = GameBlock(shape: _shapeById('single'), color: BlockColor.teal);
      final logic = GameLogic(generator: _FixedGenerator([single]));
      logic.grid.lockCell(const GridPosition(0, 5));

      for (var pass = 0; pass < 2; pass++) {
        for (final col in [0, 1, 2, 3, 4, 6, 7]) {
          final trayIndex = logic.tray.indexWhere((block) => block != null);
          logic.tryPlace(trayIndex, GridPosition(0, col));
        }
      }

      final cell = logic.grid.cellAt(const GridPosition(0, 5));
      expect(cell.isLocked, isFalse);
      expect(
        logic.grid.canPlace(_shapeById('single'), const GridPosition(0, 5)),
        isTrue,
      );
    });

    test('placing a bomb detonates the 3x3 area instead of coloring a cell', () {
      final bomb = GameBlock.bomb();
      final logic = GameLogic(generator: _FixedGenerator([bomb, bomb, bomb]));
      logic.grid.place(_shapeById('single'), const GridPosition(4, 4), BlockColor.blue);

      final placed = logic.tryPlace(0, const GridPosition(4, 3));

      expect(placed, isTrue);
      expect(logic.grid.cellAt(const GridPosition(4, 3)).isEmpty, isTrue);
      expect(logic.grid.cellAt(const GridPosition(4, 4)).isEmpty, isTrue); // caught in the blast
      expect(logic.score, greaterThan(0));
    });

    test('a bomb can be dropped on a filled cell', () {
      final bomb = GameBlock.bomb();
      final logic = GameLogic(generator: _FixedGenerator([bomb, bomb, bomb]));
      logic.grid.place(_shapeById('single'), const GridPosition(4, 4), BlockColor.blue);

      // Requiring an empty cell would make the bomb useless in exactly the
      // jammed-board situation it exists to rescue.
      expect(logic.canPlace(bomb, const GridPosition(4, 4)), isTrue);
      expect(logic.tryPlace(0, const GridPosition(4, 4)), isTrue);
      expect(logic.grid.cellAt(const GridPosition(4, 4)).isEmpty, isTrue);
    });

    test('a bomb is still playable on a completely full board', () {
      final bomb = GameBlock.bomb();
      final logic = GameLogic(generator: _FixedGenerator([bomb, bomb, bomb]));
      _fillBoardExcept(logic, const {});

      final normal =
          GameBlock(shape: _shapeById('single'), color: BlockColor.red);
      expect(logic.canPlaceAnywhere(normal), isFalse);
      expect(logic.canPlaceAnywhere(bomb), isTrue);
      expect(logic.tryPlace(0, const GridPosition(4, 4)), isTrue);
    });

    test('a wildcard piece places a colorless cell worth one point', () {
      final wildcard = GameBlock.wildcard();
      final logic =
          GameLogic(generator: _FixedGenerator([wildcard, wildcard, wildcard]));

      expect(logic.tryPlace(0, const GridPosition(2, 2)), isTrue);

      final cell = logic.grid.cellAt(const GridPosition(2, 2));
      expect(cell.isWildcard, isTrue);
      expect(cell.color, isNull);
      expect(cell.isFilled, isTrue);
      expect(logic.score, 1);
    });

    test('a mixed-color line clear scores the plain combo total', () {
      final single = GameBlock(shape: _shapeById('single'), color: BlockColor.red);
      final logic = GameLogic(generator: _FixedGenerator([single, single, single]));
      // Row 0 filled in two colors, one gap left for the tray piece.
      for (var col = 1; col < GameGrid.size; col++) {
        logic.grid.place(
          _shapeById('single'),
          GridPosition(0, col),
          col.isEven ? BlockColor.green : BlockColor.blue,
        );
      }

      logic.tryPlace(0, const GridPosition(0, 0));

      // 1 for the placed cell + 10 * 1^2 for the single line, no bonus.
      expect(logic.score, 11);
    });

    test('a line built in one color is worth double', () {
      final single = GameBlock(shape: _shapeById('single'), color: BlockColor.green);
      final logic = GameLogic(generator: _FixedGenerator([single, single, single]));
      for (var col = 1; col < GameGrid.size; col++) {
        logic.grid.place(
          _shapeById('single'),
          GridPosition(0, col),
          BlockColor.green,
        );
      }

      logic.tryPlace(0, const GridPosition(0, 0));

      // 1 for the placed cell + 10 for the line + 10 again for the bonus.
      expect(logic.score, 21);
    });

    test('a wildcard completes a same-color line and earns the bonus', () {
      final wildcard = GameBlock.wildcard();
      final logic =
          GameLogic(generator: _FixedGenerator([wildcard, wildcard, wildcard]));
      for (var col = 1; col < GameGrid.size; col++) {
        logic.grid.place(
          _shapeById('single'),
          GridPosition(0, col),
          BlockColor.teal,
        );
      }

      logic.tryPlace(0, const GridPosition(0, 0));

      // The wildcard has no color of its own, so without the adopt rule
      // this line would score 11 instead of 21.
      expect(logic.score, 21);
    });

    test('a refilled tray always contains a playable piece', () {
      // A real generator, so the tray is genuinely random; only the
      // deadlock guard in nextTray keeps it playable.
      final logic = GameLogic(generator: BlockGenerator(random: Random(7)));
      // Isolated single-cell gaps, arranged so that filling (0, 1) completes
      // neither its row nor its column — the board stays jammed, which is
      // where a purely random tray most often deals three unplayable pieces.
      _fillBoardExcept(logic, {
        const GridPosition(0, 1),
        const GridPosition(0, 3),
        const GridPosition(2, 1),
        const GridPosition(5, 2),
        const GridPosition(7, 6),
      });

      for (var slot = 1; slot < logic.tray.length; slot++) {
        logic.tray[slot] = null;
      }
      logic.tray[0] =
          GameBlock(shape: _shapeById('single'), color: BlockColor.red);
      // Emptying the last slot is what triggers the refill.
      expect(logic.tryPlace(0, const GridPosition(0, 1)), isTrue);

      expect(
        logic.tray.whereType<GameBlock>().any(logic.canPlaceAnywhere),
        isTrue,
      );
      expect(logic.isGameOver, isFalse);
    });
  });
}

/// Fills every cell on the board except [gaps], for tests that need a
/// jammed board.
void _fillBoardExcept(GameLogic logic, Set<GridPosition> gaps) {
  final single = _shapeById('single');
  for (var row = 0; row < GameGrid.size; row++) {
    for (var col = 0; col < GameGrid.size; col++) {
      final position = GridPosition(row, col);
      if (gaps.contains(position)) continue;
      logic.grid.place(single, position, BlockColor.blue);
    }
  }
}
