import 'block_color.dart';
import 'block_kind.dart';
import 'block_shape.dart';

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

  final BlockShape shape;
  final BlockColor color;
  final BlockKind kind;
}
