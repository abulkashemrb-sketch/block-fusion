import 'block_color.dart';
import 'block_shape.dart';
import 'cell.dart';
import 'grid_position.dart';

/// The 8x8 board a match is played on.
class GameGrid {
  static const int size = 8;

  final List<List<Cell>> _cells = List.generate(
    size,
    (_) => List.generate(size, (_) => const Cell.empty()),
  );

  Cell cellAt(GridPosition position) => _cells[position.row][position.col];

  bool isInBounds(GridPosition position) =>
      position.row >= 0 &&
      position.row < size &&
      position.col >= 0 &&
      position.col < size;

  /// Whether every cell [shape] would occupy, anchored at [origin], is
  /// in bounds and currently empty.
  bool canPlace(BlockShape shape, GridPosition origin) {
    for (final offset in shape.cells) {
      final target = origin + offset;
      if (!isInBounds(target) || cellAt(target).isFilled) {
        return false;
      }
    }
    return true;
  }

  void place(BlockShape shape, GridPosition origin, BlockColor color) {
    for (final offset in shape.cells) {
      final target = origin + offset;
      _cells[target.row][target.col] = Cell(color: color);
    }
  }

  /// Places a colorless wildcard cell. It fills and clears like any placed
  /// cell; the difference only shows up in [isRowMonochrome] /
  /// [isColumnMonochrome], where it adopts the line's color instead of
  /// breaking the match.
  void placeWildcard(GridPosition origin) {
    _cells[origin.row][origin.col] = const Cell.wildcard();
  }

  /// Whether every colored cell in [row] shares one color, counting
  /// wildcards as a match. Used for the same-color clear bonus.
  bool isRowMonochrome(int row) =>
      _isMonochrome([for (var col = 0; col < size; col++) _cells[row][col]]);

  /// Whether every colored cell in [col] shares one color, counting
  /// wildcards as a match. Used for the same-color clear bonus.
  bool isColumnMonochrome(int col) =>
      _isMonochrome([for (var row = 0; row < size; row++) _cells[row][col]]);

  /// A line matches when the colors it does have agree.
  ///
  /// A wildcard contributes no color of its own and never breaks the match.
  /// A locked cell does break it: it is an obstacle the player did not
  /// place, so a line running through one has not been built in one color.
  /// A line of nothing but wildcards has no color to match and scores no
  /// bonus.
  bool _isMonochrome(List<Cell> cells) {
    BlockColor? lineColor;
    for (final cell in cells) {
      if (cell.isLocked) return false;
      if (cell.isWildcard) continue;
      final color = cell.color;
      if (color == null) return false;
      if (lineColor == null) {
        lineColor = color;
      } else if (lineColor != color) {
        return false;
      }
    }
    return lineColor != null;
  }

  /// The 3x3 area a bomb affects, as offsets relative to the cell it lands
  /// on. Shared by [detonate] and the drop preview so the player is shown
  /// exactly what will be cleared.
  static const List<GridPosition> blastOffsets = [
    GridPosition(-1, -1), GridPosition(-1, 0), GridPosition(-1, 1),
    GridPosition(0, -1), GridPosition(0, 0), GridPosition(0, 1),
    GridPosition(1, -1), GridPosition(1, 0), GridPosition(1, 1),
  ];

  /// Clears every occupied cell (including locked ones, fully — a bomb
  /// ignores remaining lock hits) in the 3x3 area centered on [center].
  /// Returns how many cells were actually cleared, for scoring.
  int detonate(GridPosition center) {
    var clearedCount = 0;
    for (final offset in blastOffsets) {
      final target = center + offset;
      if (!isInBounds(target)) continue;
      if (_cells[target.row][target.col].isFilled) clearedCount++;
      _cells[target.row][target.col] = const Cell.empty();
    }
    return clearedCount;
  }

  /// Turns an empty cell into a locked obstacle. It blocks placement like
  /// any occupied cell, but chips away by one [Cell.lockLevel] per line
  /// clear that crosses it (see [clearLines]) instead of clearing outright.
  void lockCell(GridPosition position, {int level = 2}) {
    _cells[position.row][position.col] = Cell(lockLevel: level);
  }

  List<GridPosition> emptyPositions() => [
        for (var row = 0; row < size; row++)
          for (var col = 0; col < size; col++)
            if (_cells[row][col].isEmpty) GridPosition(row, col),
      ];

  /// Whether [shape] fits anywhere on the board at all — used for
  /// game-over detection.
  bool canPlaceAnywhere(BlockShape shape) {
    for (var row = 0; row < size; row++) {
      for (var col = 0; col < size; col++) {
        if (canPlace(shape, GridPosition(row, col))) return true;
      }
    }
    return false;
  }

  List<int> fullRows() => [
        for (var row = 0; row < size; row++)
          if (_cells[row].every((cell) => cell.isFilled)) row,
      ];

  List<int> fullColumns() => [
        for (var col = 0; col < size; col++)
          if (_cells.every((row) => row[col].isFilled)) col,
      ];

  /// Clears whole [rows] and [columns] in one pass.
  ///
  /// The cells where a cleared row and a cleared column cross belong to
  /// both, so they are collected into a set first: visiting them twice
  /// would take two lock hits off a locked cell for what the player sees
  /// as a single move.
  void clearLines(List<int> rows, List<int> columns) {
    final clearedPositions = <GridPosition>{};
    for (final row in rows) {
      for (var col = 0; col < size; col++) {
        clearedPositions.add(GridPosition(row, col));
      }
    }
    for (final col in columns) {
      for (var row = 0; row < size; row++) {
        clearedPositions.add(GridPosition(row, col));
      }
    }
    for (final position in clearedPositions) {
      _cells[position.row][position.col] =
          _afterClear(_cells[position.row][position.col]);
    }
  }

  /// A locked cell absorbs one hit per line clear that crosses it and only
  /// empties once its [Cell.lockLevel] reaches zero; everything else
  /// clears outright.
  Cell _afterClear(Cell cell) {
    if (!cell.isLocked) return const Cell.empty();
    final remaining = cell.lockLevel - 1;
    return remaining > 0 ? Cell(lockLevel: remaining) : const Cell.empty();
  }

  void reset() {
    for (var row = 0; row < size; row++) {
      for (var col = 0; col < size; col++) {
        _cells[row][col] = const Cell.empty();
      }
    }
  }
}
