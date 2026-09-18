import 'dart:math';

import 'package:flutter/foundation.dart';

import '../models/block_kind.dart';
import '../models/game_block.dart';
import '../models/game_grid.dart';
import '../models/grid_position.dart';
import 'block_generator.dart';

/// Owns the rules of a single match: the board, the current tray, the
/// score, and game-over detection. Pure game state — no rendering or
/// input handling lives here, which keeps it unit-testable and reusable
/// between the Flame layer and (later) Supabase score syncing.
class GameLogic extends ChangeNotifier {
  GameLogic({BlockGenerator? generator, Random? random})
      : _generator = generator ?? BlockGenerator(),
        _random = random ?? Random() {
    tray = List<GameBlock?>.from(_generator.nextTray(fits: canPlaceAnywhere));
  }

  static const int _pointsPerClearedLine = 10;

  /// Chance, each time the tray is refilled, that a new locked obstacle
  /// cell appears somewhere empty on the board.
  static const double _lockSpawnChance = 0.2;
  static const int _lockLevel = 2;

  final BlockGenerator _generator;
  final Random _random;
  final GameGrid grid = GameGrid();

  late List<GameBlock?> tray;
  int score = 0;

  /// The best score of this session. Survives [restart] on purpose — it is
  /// what the crown in the HUD shows. Persisting it across launches is the
  /// Supabase sync's job, not this class's.
  int bestScore = 0;

  bool isGameOver = false;

  /// Whether [block] may be dropped with its top-left cell on [origin].
  ///
  /// A bomb only has to land in bounds: it clears whatever sits under it,
  /// so requiring an empty cell would make it useless in exactly the
  /// jammed-board situation it exists to rescue.
  bool canPlace(GameBlock block, GridPosition origin) =>
      block.kind == BlockKind.bomb
          ? grid.isInBounds(origin)
          : grid.canPlace(block.shape, origin);

  /// Whether [block] fits anywhere on the board at all — the game-over
  /// test, and the fit check the generator uses to avoid dealing a tray
  /// that cannot be played.
  bool canPlaceAnywhere(GameBlock block) =>
      block.kind == BlockKind.bomb || grid.canPlaceAnywhere(block.shape);

  /// Attempts to place the tray piece at [trayIndex] with its top-left
  /// cell anchored at [origin]. Returns whether the placement succeeded.
  bool tryPlace(int trayIndex, GridPosition origin) {
    if (isGameOver) return false;

    final block = tray[trayIndex];
    if (block == null || !canPlace(block, origin)) {
      return false;
    }

    switch (block.kind) {
      case BlockKind.bomb:
        score += grid.detonate(origin);
      case BlockKind.wildcard:
        grid.placeWildcard(origin);
        score += 1;
      case BlockKind.normal:
        grid.place(block.shape, origin, block.color);
        score += block.shape.cells.length;
    }
    tray[trayIndex] = null;

    _resolveLineClears();
    _refillTrayIfEmpty();
    _updateGameOver();

    if (score > bestScore) bestScore = score;

    notifyListeners();
    return true;
  }

  void _resolveLineClears() {
    final rows = grid.fullRows();
    final columns = grid.fullColumns();
    final linesCleared = rows.length + columns.length;
    if (linesCleared == 0) return;

    // Counted before the clear, while the colors are still on the board.
    final monochromeLines = rows.where(grid.isRowMonochrome).length +
        columns.where(grid.isColumnMonochrome).length;

    grid.clearLines(rows, columns);

    // Clearing several lines in one move scores far more than clearing
    // them one at a time — this is the combo system for the core loop.
    final base = _pointsPerClearedLine * linesCleared * linesCleared;
    // Each line's share of that total is base / linesCleared, and a line
    // built in a single color is worth its share twice. Divides exactly:
    // base is always 10 * linesCleared^2.
    final colorBonus = base ~/ linesCleared * monochromeLines;
    score += base + colorBonus;
  }

  void _refillTrayIfEmpty() {
    if (tray.any((block) => block != null)) return;

    // The obstacle spawns first so the incoming tray is checked against the
    // board the player will actually face, not the one before the spawn.
    _maybeSpawnLockedCell();
    tray = List<GameBlock?>.from(_generator.nextTray(fits: canPlaceAnywhere));
  }

  void _maybeSpawnLockedCell() {
    if (_random.nextDouble() > _lockSpawnChance) return;

    final emptyPositions = grid.emptyPositions();
    if (emptyPositions.isEmpty) return;

    final position = emptyPositions[_random.nextInt(emptyPositions.length)];
    grid.lockCell(position, level: _lockLevel);
  }

  void _updateGameOver() {
    final remaining = tray.whereType<GameBlock>();
    isGameOver =
        remaining.isNotEmpty && remaining.every((block) => !canPlaceAnywhere(block));
  }

  /// Raises the displayed best score to [value] if it is higher.
  ///
  /// Used when a stored best score arrives from the server — it can only
  /// ever raise the crown, never lower a score the player just set.
  void raiseBestScore(int value) {
    if (value <= bestScore) return;
    bestScore = value;
    notifyListeners();
  }

  void restart() {
    grid.reset();
    tray = List<GameBlock?>.from(_generator.nextTray(fits: canPlaceAnywhere));
    score = 0;
    isGameOver = false;
    notifyListeners();
  }
}
