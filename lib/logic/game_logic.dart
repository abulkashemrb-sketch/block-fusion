import 'dart:math';

import 'package:flutter/foundation.dart';

import '../models/block_kind.dart';
import '../models/game_block.dart';
import '../models/game_grid.dart';
import '../models/game_snapshot.dart';
import '../models/grid_position.dart';
import '../models/move_result.dart';
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
  ///
  /// A fifth of refills was too much. Over a typical game that is five or
  /// six obstacles, each costing two line clears to remove, on a board that
  /// is already the whole difficulty — the genre this is modelled on ships
  /// no obstacles at all in its main mode.
  static const double _lockSpawnChance = 0.12;
  static const int _lockLevel = 2;

  /// Refills before obstacles can appear at all.
  ///
  /// The opening of a game is where a new player decides whether they
  /// understand it. Dropping a cell they cannot use into the first minute
  /// reads as the game being broken rather than hard.
  static const int _lockGraceRefills = 3;

  /// The board is not allowed to accumulate more obstacles than this at
  /// once. Without a cap, an unlucky run of spawns can crowd the board
  /// faster than clears can open it, which is a loss the player had no
  /// hand in.
  static const int _maxLockedCells = 3;

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

  /// Counts refills, so obstacles can be held back for the opening.
  int _refills = 0;

  /// What the most recent successful placement did, or `null` before the
  /// first move and after a restart.
  ///
  /// The game layer reads this on each notification to decide what to
  /// animate. It is the only channel by which the renderer learns that a
  /// cell *cleared* rather than simply never having been filled.
  MoveResult? lastMove;

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

    final scoreBefore = score;
    final bestBefore = bestScore;
    final filledBefore = grid.filledPositions();

    final placedCells = <GridPosition>[];
    switch (block.kind) {
      case BlockKind.bomb:
        score += grid.detonate(origin);
      case BlockKind.wildcard:
        grid.placeWildcard(origin);
        placedCells.add(origin);
        score += 1;
      case BlockKind.normal:
        grid.place(block.shape, origin, block.color);
        placedCells.addAll(block.shape.cells.map((offset) => origin + offset));
        score += block.shape.cells.length;
    }
    tray[trayIndex] = null;

    // A bomb empties cells as its placement; anything that was filled and
    // is not any more went up in the blast.
    final filledAfterPiece = grid.filledPositions();
    final blastCleared = filledBefore.difference(filledAfterPiece);

    final clears = _resolveLineClears();
    // Whatever the clear emptied, including cells this very piece just
    // filled. A locked cell that only lost a level is still filled, so it
    // correctly stays out of this set.
    final lineCleared = filledAfterPiece.difference(grid.filledPositions());

    _refillTrayIfEmpty();
    _updateGameOver();

    final isNewBest = score > bestBefore;
    if (isNewBest) bestScore = score;

    lastMove = MoveResult(
      placedCells: placedCells,
      clearedCells: [...blastCleared, ...lineCleared],
      linesCleared: clears.lines,
      monochromeLines: clears.monochromeLines,
      pointsGained: score - scoreBefore,
      isNewBest: isNewBest,
    );

    notifyListeners();
    return true;
  }

  ({int lines, int monochromeLines}) _resolveLineClears() {
    final rows = grid.fullRows();
    final columns = grid.fullColumns();
    final linesCleared = rows.length + columns.length;
    if (linesCleared == 0) return (lines: 0, monochromeLines: 0);

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

    return (lines: linesCleared, monochromeLines: monochromeLines);
  }

  void _refillTrayIfEmpty() {
    if (tray.any((block) => block != null)) return;

    _refills++;
    // The obstacle spawns first so the incoming tray is checked against the
    // board the player will actually face, not the one before the spawn.
    _maybeSpawnLockedCell();
    tray = List<GameBlock?>.from(
      _generator.nextTray(fits: canPlaceAnywhere, fullness: fullness),
    );
  }

  /// How much of the board is occupied, 0 to 1. The generator uses it to
  /// favour smaller pieces as room runs out.
  double get fullness =>
      grid.filledPositions().length / (GameGrid.size * GameGrid.size);

  void _maybeSpawnLockedCell() {
    if (_refills <= _lockGraceRefills) return;
    if (_lockedCellCount >= _maxLockedCells) return;
    if (_random.nextDouble() > _lockSpawnChance) return;

    final emptyPositions = grid.emptyPositions();
    if (emptyPositions.isEmpty) return;

    final position = emptyPositions[_random.nextInt(emptyPositions.length)];
    grid.lockCell(position, level: _lockLevel);
  }

  int get _lockedCellCount => grid
      .filledPositions()
      .where((position) => grid.cellAt(position).isLocked)
      .length;

  void _updateGameOver() {
    final remaining = tray.whereType<GameBlock>();
    isGameOver =
        remaining.isNotEmpty && remaining.every((block) => !canPlaceAnywhere(block));
  }

  /// The current game, in a form that can be written down.
  GameSnapshot toSnapshot() => GameSnapshot(
        cells: grid.snapshotCells(),
        tray: List<GameBlock?>.from(tray),
        score: score,
        bestScore: bestScore,
      );

  /// Puts a saved game back. Returns whether it was accepted.
  ///
  /// A snapshot that does not fit the board is refused outright rather than
  /// partly applied, and game-over is recomputed from the restored board
  /// instead of being trusted from the save — the rules may have changed
  /// since it was written.
  bool restore(GameSnapshot snapshot) {
    if (!grid.restoreCells(snapshot.cells)) return false;

    tray = List<GameBlock?>.from(snapshot.tray);
    // A save with an empty tray would leave the player with nothing to
    // place and no refill coming, so deal a fresh one.
    if (tray.isEmpty || tray.every((block) => block == null)) {
      tray = List<GameBlock?>.from(_generator.nextTray(fits: canPlaceAnywhere));
    }
    score = snapshot.score;
    bestScore = snapshot.bestScore > score ? snapshot.bestScore : score;
    lastMove = null;
    _updateGameOver();
    notifyListeners();
    return true;
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
    lastMove = null;
    _refills = 0;
    notifyListeners();
  }
}
