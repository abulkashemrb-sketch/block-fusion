import 'package:flutter/foundation.dart';

import '../models/game_block.dart';
import '../models/game_grid.dart';
import '../models/grid_position.dart';
import 'block_generator.dart';

/// Owns the rules of a single match: the board, the current tray, the
/// score, and game-over detection. Pure game state — no rendering or
/// input handling lives here, which keeps it unit-testable and reusable
/// between the Flame layer and (later) Supabase score syncing.
class GameLogic extends ChangeNotifier {
  GameLogic({BlockGenerator? generator}) : _generator = generator ?? BlockGenerator() {
    tray = List<GameBlock?>.from(_generator.nextTray());
  }

  static const int _pointsPerClearedLine = 10;

  final BlockGenerator _generator;
  final GameGrid grid = GameGrid();

  late List<GameBlock?> tray;
  int score = 0;
  bool isGameOver = false;

  /// Attempts to place the tray piece at [trayIndex] with its top-left
  /// cell anchored at [origin]. Returns whether the placement succeeded.
  bool tryPlace(int trayIndex, GridPosition origin) {
    if (isGameOver) return false;

    final block = tray[trayIndex];
    if (block == null || !grid.canPlace(block.shape, origin)) {
      return false;
    }

    grid.place(block.shape, origin, block.color);
    score += block.shape.cells.length;
    tray[trayIndex] = null;

    _resolveLineClears();
    _refillTrayIfEmpty();
    _updateGameOver();

    notifyListeners();
    return true;
  }

  void _resolveLineClears() {
    final rows = grid.fullRows();
    final columns = grid.fullColumns();
    final linesCleared = rows.length + columns.length;
    if (linesCleared == 0) return;

    grid.clearLines(rows, columns);
    // Clearing several lines in one move scores far more than clearing
    // them one at a time — this is the combo system for the core loop.
    score += _pointsPerClearedLine * linesCleared * linesCleared;
  }

  void _refillTrayIfEmpty() {
    if (tray.every((block) => block == null)) {
      tray = List<GameBlock?>.from(_generator.nextTray());
    }
  }

  void _updateGameOver() {
    final remaining = tray.whereType<GameBlock>();
    isGameOver = remaining.isNotEmpty &&
        remaining.every((block) => !grid.canPlaceAnywhere(block.shape));
  }

  void restart() {
    grid.reset();
    tray = _generator.nextTray();
    score = 0;
    isGameOver = false;
    notifyListeners();
  }
}
