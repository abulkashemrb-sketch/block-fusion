import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../../logic/game_logic.dart';
import '../../models/grid_position.dart';
import '../../models/move_result.dart';
import '../../theme/app_theme.dart';
import '../block_palette.dart';
import 'clear_burst_component.dart';
import 'floating_text_component.dart';
import 'grid_component.dart';

/// Turns each move's [MoveResult] into something the player can see.
///
/// A plain controller rather than a Component, for the same reason
/// [TrayController] is one: it owns a lifecycle, not a place on screen, and
/// making it a component would put a coordinate-space boundary between the
/// effects and the board they belong to. Effects are added to
/// [gridComponent] so their positions are board-local.
///
/// It reads the *colours* off the board before the move is applied, because
/// by the time it runs the cells are already empty — see [rememberBoard].
class EffectsController {
  EffectsController({required this.logic, required this.gridComponent}) {
    _rememberBoard();
    logic.addListener(_onMove);
  }

  final GameLogic logic;
  final GridComponent gridComponent;

  /// The colour of every filled cell as of the last frame, so a burst can
  /// be drawn in the colour the cell *had*.
  final Map<GridPosition, Color> _colorBefore = {};

  int _burstSeed = 0;

  void dispose() => logic.removeListener(_onMove);

  void _rememberBoard() {
    _colorBefore.clear();
    for (final position in logic.grid.filledPositions()) {
      final cell = logic.grid.cellAt(position);
      final color = cell.color;
      _colorBefore[position] = color != null
          ? blockColorToColor(color)
          // Wildcards and locked cells have no colour of their own; give
          // them something that still reads as "a block was here".
          : (cell.isWildcard ? Colors.white : const Color(0xFF4B6E93));
    }
  }

  void _onMove() {
    final move = logic.lastMove;
    if (move == null || gridComponent.cellSize <= 0) {
      _rememberBoard();
      return;
    }

    _spawnBursts(move);
    _spawnLabels(move);
    _rememberBoard();
  }

  void _spawnBursts(MoveResult move) {
    final cellSize = gridComponent.cellSize;
    for (final position in move.clearedCells) {
      gridComponent.add(
        ClearBurstComponent(
          color: _colorBefore[position] ?? Colors.white,
          cellSize: cellSize,
          position: _topLeftOf(position),
          seed: _burstSeed++,
        ),
      );
    }
  }

  void _spawnLabels(MoveResult move) {
    if (!move.clearedAnything) return;
    final cellSize = gridComponent.cellSize;

    // Anchor the labels on the middle of what was cleared, so the feedback
    // appears where the player was looking.
    final centre = _centreOf(move.clearedCells, cellSize);

    gridComponent.add(
      FloatingTextComponent(
        text: '+${move.pointsGained}',
        color: Colors.white,
        fontSize: cellSize * 0.62,
        position: centre,
      ),
    );

    if (move.linesCleared >= 2) {
      gridComponent.add(
        FloatingTextComponent(
          text: 'COMBO x${move.linesCleared}',
          color: AppTheme.accent,
          fontSize: cellSize * 0.52,
          position: centre.clone()..y -= cellSize * 0.9,
          delay: 0.12,
        ),
      );
    }

    if (move.monochromeLines > 0) {
      gridComponent.add(
        FloatingTextComponent(
          text: 'SAME COLOUR!',
          color: AppTheme.secondary,
          fontSize: cellSize * 0.44,
          position: centre.clone()..y += cellSize * 0.9,
          delay: 0.22,
        ),
      );
    }

    if (move.isNewBest) {
      gridComponent.add(
        FloatingTextComponent(
          text: 'NEW BEST!',
          color: AppTheme.accent,
          fontSize: cellSize * 0.6,
          position: Vector2(gridComponent.size.x / 2, cellSize * 1.5),
          delay: 0.3,
          duration: 1.1,
        ),
      );
    }
  }

  Vector2 _topLeftOf(GridPosition position) =>
      Vector2(position.col * gridComponent.cellSize,
          position.row * gridComponent.cellSize);

  Vector2 _centreOf(List<GridPosition> positions, double cellSize) {
    var row = 0.0;
    var col = 0.0;
    for (final position in positions) {
      row += position.row;
      col += position.col;
    }
    return Vector2(
      (col / positions.length + 0.5) * cellSize,
      (row / positions.length + 0.5) * cellSize,
    );
  }
}
