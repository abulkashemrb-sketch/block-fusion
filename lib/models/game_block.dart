import 'block_color.dart';
import 'block_shape.dart';

/// A concrete piece offered to the player: a [BlockShape] painted with one
/// [BlockColor].
class GameBlock {
  const GameBlock({required this.shape, required this.color});

  final BlockShape shape;
  final BlockColor color;
}
