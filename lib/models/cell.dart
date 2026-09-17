import 'block_color.dart';

/// A single square on the [GameGrid].
///
/// A `null` [color] means the cell is empty.
class Cell {
  const Cell({this.color});
  const Cell.empty() : color = null;

  final BlockColor? color;

  bool get isEmpty => color == null;
  bool get isFilled => color != null;
}
