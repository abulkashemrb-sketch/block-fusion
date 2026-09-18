import 'block_color.dart';
import 'block_kind.dart';
import 'block_shape.dart';
import 'game_grid.dart';
import 'grid_position.dart';

/// A concrete piece offered to the player: a [BlockShape] painted with one
/// [BlockColor], or a special power-up piece identified by [kind].
class GameBlock {
  const GameBlock({
    required this.shape,
    required this.color,
    this.kind = BlockKind.normal,
  });

  /// A bomb piece: occupies a single cell like any other placement, but
  /// detonates its surroundings instead of leaving a colored block behind
  /// (see [GameGrid.detonate]). Its [color] is unused for rendering.
  GameBlock.bomb()
      : shape = BlockShape.library.firstWhere((shape) => shape.id == 'single'),
        color = BlockColor.red,
        kind = BlockKind.bomb;

  /// A wildcard piece: a single cell with no color of its own. It counts as
  /// whatever color the line it completes is made of, which is how a
  /// same-color line stays reachable once the board is mixed. Its [color]
  /// is unused for rendering.
  GameBlock.wildcard()
      : shape = BlockShape.library.firstWhere((shape) => shape.id == 'single'),
        color = BlockColor.red,
        kind = BlockKind.wildcard;

  final BlockShape shape;
  final BlockColor color;
  final BlockKind kind;

  /// The cells a drop preview should highlight, as offsets from the cell
  /// the piece is anchored on. A bomb highlights the area it will clear
  /// rather than the single cell it occupies, so the player can aim it.
  List<GridPosition> get previewOffsets =>
      kind == BlockKind.bomb ? GameGrid.blastOffsets : shape.cells;
}
