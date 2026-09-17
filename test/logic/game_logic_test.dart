import 'package:flutter_test/flutter_test.dart';

import 'package:block_fusion/logic/block_generator.dart';
import 'package:block_fusion/logic/game_logic.dart';
import 'package:block_fusion/models/block_color.dart';
import 'package:block_fusion/models/block_shape.dart';
import 'package:block_fusion/models/game_block.dart';
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
      final quad = GameBlock(shape: _shapeById('tetra_i_h'), color: BlockColor.green);
      final filler = GameBlock(shape: _shapeById('domino_h'), color: BlockColor.yellow);
      final logic = GameLogic(generator: _FixedGenerator([quad, quad, filler]));

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
    });
  });
}
