import 'block_color.dart';

/// A single square on the [GameGrid].
///
/// A cell is either empty, holds a placed block's [color], is a wildcard,
/// or is a locked obstacle ([lockLevel] > 0). A locked cell has no [color],
/// can't be placed on, but still counts as occupied for line-completion —
/// clearing its line chips [lockLevel] down by one instead of emptying it
/// outright.
///
/// A wildcard cell is colorless too, but unlike a locked cell it is a cell
/// the player placed: it clears normally, and it matches whatever color
/// the rest of its line has when the same-color bonus is scored.
class Cell {
  const Cell({this.color, this.lockLevel = 0, this.isWildcard = false});
  const Cell.empty() : color = null, lockLevel = 0, isWildcard = false;
  const Cell.wildcard() : color = null, lockLevel = 0, isWildcard = true;

  final BlockColor? color;
  final int lockLevel;
  final bool isWildcard;

  bool get isLocked => lockLevel > 0;
  bool get isFilled => color != null || lockLevel > 0 || isWildcard;
  bool get isEmpty => !isFilled;
}
