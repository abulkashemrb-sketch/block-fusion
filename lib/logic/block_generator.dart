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

  /// Chance that a generated piece is a bomb power-up instead of a normal
  /// colored shape.
  static const double _bombChance = 0.12;

  /// Chance of a wildcard piece. Rarer than a bomb: it is the key to the
  /// same-color bonus, and handing one out too often turns that bonus from
  /// something the player sets up into something that just happens.
  static const double _wildcardChance = 0.08;

  /// How many random trays to draw before falling back to a tray that is
  /// built to fit. Small on purpose: a fully random draw is playable on
  /// almost any board, so the retries rarely run and never loop long.
  static const int _maxTrayAttempts = 8;

  final Random _random;

  GameBlock next() {
    final roll = _random.nextDouble();
    if (roll < _bombChance) {
      return GameBlock.bomb();
    }
    if (roll < _bombChance + _wildcardChance) {
      return GameBlock.wildcard();
    }
    final shape = BlockShape.library[_random.nextInt(BlockShape.library.length)];
    return GameBlock(shape: shape, color: _randomColor());
  }

  /// Deals [count] pieces.
  ///
  /// With [fits] supplied, the tray is guaranteed to contain at least one
  /// piece that can be played on the current board. That is the whole of
  /// the difficulty adjustment: the draw stays random, it just never hands
  /// the player a dead tray and calls it a loss. Without [fits] the draw is
  /// purely random.
  List<GameBlock> nextTray({
    int count = 3,
    bool Function(GameBlock block)? fits,
  }) {
    if (fits == null) return List.generate(count, (_) => next());

    for (var attempt = 0; attempt < _maxTrayAttempts; attempt++) {
      final tray = List.generate(count, (_) => next());
      if (tray.any(fits)) return tray;
    }
    return _trayWithGuaranteedFit(count, fits);
  }

  /// A random tray with one slot replaced by the smallest piece that still
  /// fits. If nothing in the library fits, the board is genuinely full and
  /// the caller's game-over check should fire — so the random tray is
  /// returned untouched rather than faking a move that does not exist.
  List<GameBlock> _trayWithGuaranteedFit(
    int count,
    bool Function(GameBlock block) fits,
  ) {
    final tray = List.generate(count, (_) => next());
    final rescue = _smallestFitting(fits);
    if (rescue != null) {
      tray[_random.nextInt(count)] = rescue;
    }
    return tray;
  }

  GameBlock? _smallestFitting(bool Function(GameBlock block) fits) {
    final byCellCount = [...BlockShape.library]
      ..sort((a, b) => a.cells.length.compareTo(b.cells.length));
    for (final shape in byCellCount) {
      final candidate = GameBlock(shape: shape, color: _randomColor());
      if (fits(candidate)) return candidate;
    }
    return null;
  }

  BlockColor _randomColor() =>
      BlockColor.values[_random.nextInt(BlockColor.values.length)];
}
