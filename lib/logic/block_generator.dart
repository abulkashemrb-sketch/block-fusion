import 'dart:math';

import '../models/block_color.dart';
import '../models/block_shape.dart';
import '../models/game_block.dart';

/// Produces random tray pieces.
///
/// Isolated behind its own class so difficulty tuning (e.g. weighting
/// shapes by size) can be added later without touching [GameLogic].
class BlockGenerator {
  BlockGenerator({Random? random}) : _random = random ?? Random();

  final Random _random;

  GameBlock next() {
    final shape = BlockShape.library[_random.nextInt(BlockShape.library.length)];
    final color = BlockColor.values[_random.nextInt(BlockColor.values.length)];
    return GameBlock(shape: shape, color: color);
  }

  List<GameBlock> nextTray({int count = 3}) =>
      List.generate(count, (_) => next());
}
