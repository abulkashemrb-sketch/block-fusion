import 'package:flutter_test/flutter_test.dart';

import 'package:block_fusion/models/block_color.dart';
import 'package:block_fusion/models/block_shape.dart';
import 'package:block_fusion/models/game_grid.dart';
import 'package:block_fusion/models/grid_position.dart';

BlockShape _shapeById(String id) =>
    BlockShape.library.firstWhere((shape) => shape.id == id);

void main() {
  group('GameGrid', () {
    test('starts empty', () {
      final grid = GameGrid();
      for (var row = 0; row < GameGrid.size; row++) {
        for (var col = 0; col < GameGrid.size; col++) {
          expect(grid.cellAt(GridPosition(row, col)).isEmpty, isTrue);
        }
      }
    });

    test('canPlace is false when the shape would fall out of bounds', () {
      final grid = GameGrid();
      final shape = _shapeById('tetra_i_h'); // 4 cells wide
      expect(grid.canPlace(shape, const GridPosition(0, 6)), isFalse);
    });

    test('canPlace is false when a target cell is already filled', () {
      final grid = GameGrid()
        ..place(_shapeById('single'), const GridPosition(0, 0), BlockColor.red);

      expect(grid.canPlace(_shapeById('domino_h'), const GridPosition(0, 0)), isFalse);
    });

    test('fullRows/fullColumns detect completed lines only', () {
      final grid = GameGrid();
      for (var col = 0; col < GameGrid.size; col++) {
        grid.place(_shapeById('single'), GridPosition(3, col), BlockColor.blue);
      }

      expect(grid.fullRows(), [3]);
      expect(grid.fullColumns(), isEmpty);
    });

    test('clearLines empties the given rows and columns', () {
      final grid = GameGrid();
      for (var col = 0; col < GameGrid.size; col++) {
        grid.place(_shapeById('single'), GridPosition(3, col), BlockColor.blue);
      }

      grid.clearLines(grid.fullRows(), grid.fullColumns());

      expect(grid.cellAt(const GridPosition(3, 0)).isEmpty, isTrue);
    });

    test('canPlaceAnywhere is false once the board is completely full', () {
      final grid = GameGrid();
      for (var row = 0; row < GameGrid.size; row++) {
        for (var col = 0; col < GameGrid.size; col++) {
          grid.place(_shapeById('single'), GridPosition(row, col), BlockColor.green);
        }
      }

      expect(grid.canPlaceAnywhere(_shapeById('single')), isFalse);
    });
  });
}
