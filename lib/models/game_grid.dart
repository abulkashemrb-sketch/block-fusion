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

  void clearLines(List<int> rows, List<int> columns) {
    for (final row in rows) {
      for (var col = 0; col < size; col++) {
        _cells[row][col] = _afterClear(_cells[row][col]);
      }
    }
    for (final col in columns) {
      for (var row = 0; row < size; row++) {
        _cells[row][col] = _afterClear(_cells[row][col]);
      }
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
