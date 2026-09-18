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

    test('a locked cell on a cleared row and column only takes one hit', () {
      final grid = GameGrid()..lockCell(const GridPosition(3, 3), level: 2);
      // Fill everything else on row 3 and column 3 so both complete at once.
      for (var i = 0; i < GameGrid.size; i++) {
        if (i != 3) {
          grid
            ..place(_shapeById('single'), GridPosition(3, i), BlockColor.blue)
            ..place(_shapeById('single'), GridPosition(i, 3), BlockColor.blue);
        }
      }

      grid.clearLines(grid.fullRows(), grid.fullColumns());

      // One move, one hit: the cell sits on both lines but must not be
      // chipped twice, or a two-hit obstacle opens in a single clear.
      final cell = grid.cellAt(const GridPosition(3, 3));
      expect(cell.isLocked, isTrue);
      expect(cell.lockLevel, 1);
    });

    test('a row built in one color is monochrome', () {
      final grid = GameGrid();
      for (var col = 0; col < GameGrid.size; col++) {
        grid.place(_shapeById('single'), GridPosition(2, col), BlockColor.green);
      }

      expect(grid.isRowMonochrome(2), isTrue);
    });

    test('one odd color breaks the match', () {
      final grid = GameGrid();
      for (var col = 0; col < GameGrid.size; col++) {
        grid.place(_shapeById('single'), GridPosition(2, col), BlockColor.green);
      }
      grid.place(_shapeById('single'), const GridPosition(2, 5), BlockColor.red);

      expect(grid.isRowMonochrome(2), isFalse);
    });

    test('a wildcard adopts the color of the line around it', () {
      final grid = GameGrid();
      for (var col = 0; col < GameGrid.size; col++) {
        grid.place(_shapeById('single'), GridPosition(2, col), BlockColor.green);
      }
      grid.placeWildcard(const GridPosition(2, 4));

      expect(grid.isRowMonochrome(2), isTrue);
    });

    test('a locked cell disqualifies the line from the color bonus', () {
      final grid = GameGrid();
      for (var col = 0; col < GameGrid.size; col++) {
        grid.place(_shapeById('single'), GridPosition(2, col), BlockColor.green);
      }
      grid.lockCell(const GridPosition(2, 4), level: 2);

      expect(grid.isRowMonochrome(2), isFalse);
    });

    test('a line of nothing but wildcards has no color to match', () {
      final grid = GameGrid();
      for (var col = 0; col < GameGrid.size; col++) {
        grid.placeWildcard(GridPosition(2, col));
      }

      expect(grid.isRowMonochrome(2), isFalse);
    });

    test('columns are matched the same way as rows', () {
      final grid = GameGrid();
      for (var row = 0; row < GameGrid.size; row++) {
        grid.place(_shapeById('single'), GridPosition(row, 3), BlockColor.purple);
      }

      expect(grid.isColumnMonochrome(3), isTrue);
      expect(grid.isColumnMonochrome(4), isFalse);
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
