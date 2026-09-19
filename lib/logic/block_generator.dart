import 'dart:math';

import '../models/block_color.dart';
import '../models/block_shape.dart';
import '../models/game_block.dart';

/// Produces random tray pieces.
///
/// Isolated behind its own class so difficulty tuning (e.g. weighting
/// shapes by size) can be added later without touching [GameLogic].
class BlockGenerator {
  BlockGenerator({Random? random, double? crowdingBias})
      : _random = random ?? Random(),
        crowdingBias = crowdingBias ?? defaultCrowdingBias;

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

  /// How hard a crowded board pushes the draw towards smaller pieces.
  ///
  /// Each shape is weighted by `(1 / cells)^(fullness * this)`. At zero
  /// fullness that is 1 for every shape, so an empty board deals from the
  /// library evenly and the game keeps its variety. As the board fills the
  /// exponent rises and the big shapes fall away — on a nearly full board a
  /// single cell becomes about thirty times likelier than the five-cell
  /// plus.
  ///
  /// Without this, a board with two gaps left is as likely to be handed a
  /// five-cell piece as a one-cell piece, which is not difficulty so much
  /// as a coin flip about whether the game ends.
  ///
  /// 2.0 was chosen by sweeping it against a simulated player
  /// (`test/logic/difficulty_simulation_test.dart`). Off, a game ran 90
  /// moves and the unluckiest tenth ended inside 34 — about a minute, which
  /// is the version that was reported as too hard. At 2.0 those become 167
  /// and 56. Pushing on to 3.0 buys a little more, but stretches the
  /// longest tenth past 360 moves, and a casual game that will not end is
  /// its own kind of tiring.
  static const double defaultCrowdingBias = 2.0;

  /// Overridable so difficulty can be swept in a simulation rather than
  /// guessed at.
  final double crowdingBias;

  final Random _random;

  /// Draws one piece.
  ///
  /// [fullness] is how much of the board is occupied, 0 to 1. It only
  /// shifts the odds between shapes; a bomb or a wildcard is equally likely
  /// whatever the board looks like, because those are the pieces that
  /// rescue a crowded board and making them rarer when they are needed
  /// would be backwards.
  GameBlock next({double fullness = 0}) {
    final roll = _random.nextDouble();
    if (roll < _bombChance) {
      return GameBlock.bomb();
    }
    if (roll < _bombChance + _wildcardChance) {
      return GameBlock.wildcard();
    }
    return GameBlock(shape: _weightedShape(fullness), color: _randomColor());
  }

  BlockShape _weightedShape(double fullness) {
    final exponent = fullness.clamp(0.0, 1.0) * crowdingBias;
    if (exponent == 0) {
      return BlockShape.library[_random.nextInt(BlockShape.library.length)];
    }

    final weights = [
      for (final shape in BlockShape.library)
        pow(1 / shape.cells.length, exponent).toDouble(),
    ];
    final total = weights.reduce((a, b) => a + b);

    var ticket = _random.nextDouble() * total;
    for (var i = 0; i < weights.length; i++) {
      ticket -= weights[i];
      if (ticket <= 0) return BlockShape.library[i];
    }
    return BlockShape.library.last;
  }

  /// Deals [count] pieces.
  ///
  /// Two things make the draw kinder than pure chance, and neither of them
  /// plays the game for the player. [fullness] tilts the odds towards
  /// smaller shapes as the board crowds, and [fits] guarantees at least one
  /// piece in the tray can be placed — so a game ends because the player
  /// ran out of room, never because the deal was impossible.
  List<GameBlock> nextTray({
    int count = 3,
    bool Function(GameBlock block)? fits,
    double fullness = 0,
  }) {
    if (fits == null) {
      return List.generate(count, (_) => next(fullness: fullness));
    }

    for (var attempt = 0; attempt < _maxTrayAttempts; attempt++) {
      final tray = List.generate(count, (_) => next(fullness: fullness));
      if (tray.any(fits)) return tray;
    }
    return _trayWithGuaranteedFit(count, fits, fullness);
  }

  /// A random tray with one slot replaced by the smallest piece that still
  /// fits. If nothing in the library fits, the board is genuinely full and
  /// the caller's game-over check should fire — so the random tray is
  /// returned untouched rather than faking a move that does not exist.
  List<GameBlock> _trayWithGuaranteedFit(
    int count,
    bool Function(GameBlock block) fits,
    double fullness,
  ) {
    final tray = List.generate(count, (_) => next(fullness: fullness));
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
