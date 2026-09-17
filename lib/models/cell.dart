import 'block_color.dart';

/// A single square on the [GameGrid].
///
/// A cell is either empty, holds a placed block's [color], or is a locked
/// obstacle ([lockLevel] > 0). A locked cell has no [color], can't be
/// placed on, but still counts as occupied for line-completion — clearing
/// its line chips [lockLevel] down by one instead of emptying it outright.
class Cell {
  const Cell({this.color, this.lockLevel = 0});
  const Cell.empty() : color = null, lockLevel = 0;

  final BlockColor? color;
  final int lockLevel;

  bool get isLocked => lockLevel > 0;
  bool get isFilled => color != null || lockLevel > 0;
  bool get isEmpty => !isFilled;
}
