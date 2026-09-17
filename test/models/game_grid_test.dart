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

    test('lockCell creates an obstacle that blocks placement without a color', () {
      final grid = GameGrid()..lockCell(const GridPosition(2, 2));
      final cell = grid.cellAt(const GridPosition(2, 2));

      expect(cell.isLocked, isTrue);
      expect(cell.color, isNull);
      expect(grid.canPlace(_shapeById('single'), const GridPosition(2, 2)), isFalse);
    });

    test('emptyPositions excludes both filled and locked cells', () {
      final grid = GameGrid()
        ..place(_shapeById('single'), const GridPosition(0, 0), BlockColor.red)
        ..lockCell(const GridPosition(0, 1));

      final empties = grid.emptyPositions();

      expect(empties.contains(const GridPosition(0, 0)), isFalse);
      expect(empties.contains(const GridPosition(0, 1)), isFalse);
      expect(empties.length, GameGrid.size * GameGrid.size - 2);
    });

    test('clearLines chips a locked cell down by one instead of clearing it', () {
      final grid = GameGrid()..lockCell(const GridPosition(0, 0), level: 2);

      grid.clearLines([0], const []);

      final cell = grid.cellAt(const GridPosition(0, 0));
      expect(cell.isLocked, isTrue);
      expect(cell.lockLevel, 1);
    });

    test('clearLines fully empties a locked cell once its level reaches zero', () {
      final grid = GameGrid()..lockCell(const GridPosition(0, 0), level: 1);

      grid.clearLines([0], const []);

      expect(grid.cellAt(const GridPosition(0, 0)).isEmpty, isTrue);
    });

    test('detonate clears the 3x3 area around a cell, including locked ones fully', () {
      final grid = GameGrid()
        ..place(_shapeById('single'), const GridPosition(3, 3), BlockColor.red)
        ..lockCell(const GridPosition(3, 4), level: 2);

      final cleared = grid.detonate(const GridPosition(3, 3));

      expect(cleared, 2); // the placed block + the locked cell
      expect(grid.cellAt(const GridPosition(3, 3)).isEmpty, isTrue);
      expect(grid.cellAt(const GridPosition(3, 4)).isEmpty, isTrue);
    });

    test('detonate does not throw when the blast radius runs off the board', () {
      final grid = GameGrid()
        ..place(_shapeById('single'), const GridPosition(0, 0), BlockColor.blue);

      final cleared = grid.detonate(const GridPosition(0, 0));

      expect(cleared, 1);
      expect(grid.cellAt(const GridPosition(0, 0)).isEmpty, isTrue);
    });
  });
}
