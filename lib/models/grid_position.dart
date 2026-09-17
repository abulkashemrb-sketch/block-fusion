/// An immutable (row, column) coordinate.
///
/// Used both for absolute positions on the [GameGrid] and for the
/// relative cell offsets that make up a [BlockShape] — the two are added
/// together to find where a shape's cells land on the board.
class GridPosition {
  const GridPosition(this.row, this.col);

  final int row;
  final int col;

  GridPosition operator +(GridPosition other) =>
      GridPosition(row + other.row, col + other.col);

  @override
  bool operator ==(Object other) =>
      other is GridPosition && other.row == row && other.col == col;

  @override
  int get hashCode => Object.hash(row, col);

  @override
  String toString() => 'GridPosition($row, $col)';
}
