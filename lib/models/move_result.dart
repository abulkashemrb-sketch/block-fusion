import 'grid_position.dart';

/// What a single successful placement did.
///
/// The rules layer decides all of this; the game layer reads it to decide
/// what to animate. Without it the renderer only ever sees the board's
/// *new* state and has no way to know a cell was cleared rather than never
/// filled — the difference between a block bursting and a block silently
/// vanishing.
///
/// Plain data, so the scoring and clearing rules stay unit-testable.
class MoveResult {
  const MoveResult({
    required this.placedCells,
    required this.clearedCells,
    required this.linesCleared,
    required this.monochromeLines,
    required this.pointsGained,
    required this.isNewBest,
  });

  /// Cells the piece itself landed on. Empty for a bomb, which leaves
  /// nothing behind.
  final List<GridPosition> placedCells;

  /// Cells that went from filled to empty this move — a completed line, a
  /// bomb's blast, or both. A locked cell that only lost a level is not
  /// here, because it did not clear.
  final List<GridPosition> clearedCells;

  final int linesCleared;

  /// How many of those lines were a single colour, and so scored double.
  final int monochromeLines;

  /// Total score added by this move, placement and clears together.
  final int pointsGained;

  /// Whether this move set a new best score.
  final bool isNewBest;

  bool get clearedAnything => clearedCells.isNotEmpty;
}
