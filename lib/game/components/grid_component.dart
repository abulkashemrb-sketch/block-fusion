import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../../logic/game_logic.dart';
import '../../models/game_grid.dart';
import '../../models/grid_position.dart';
import '../block_palette.dart';

/// Renders the 8x8 board and an optional placement preview overlay.
class GridComponent extends PositionComponent {
  GridComponent({required this.logic});

  final GameLogic logic;

  double cellSize = 0;

  Set<GridPosition> _previewCells = {};
  bool _previewValid = false;

  void layout(Vector2 canvasSize) {
    const gridSize = GameGrid.size;
    final maxWidth = canvasSize.x - 32;
    final maxHeight = canvasSize.y * 0.55;
    cellSize = (maxWidth < maxHeight ? maxWidth : maxHeight) / gridSize;
    size = Vector2.all(cellSize * gridSize);
    position = Vector2((canvasSize.x - size.x) / 2, canvasSize.y * 0.12);
  }

  /// Highlights the cells [shapeCells] (relative offsets) would occupy if
  /// anchored at [origin], colored by whether that placement is [valid].
  void setPreview(
    GridPosition origin,
    Iterable<GridPosition> shapeCells,
    bool valid,
  ) {
    _previewCells = shapeCells.map((offset) => origin + offset).toSet();
    _previewValid = valid;
  }

  void clearPreview() {
    _previewCells = {};
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.x, size.y),
        const Radius.circular(12),
      ),
      Paint()..color = const Color(0xFF1B1E2B),
    );

    for (var row = 0; row < GameGrid.size; row++) {
      for (var col = 0; col < GameGrid.size; col++) {
        final position = GridPosition(row, col);
        final cell = logic.grid.cellAt(position);
        final rect = Rect.fromLTWH(
          col * cellSize,
          row * cellSize,
          cellSize,
          cellSize,
        ).deflate(2);
        final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(6));

        if (cell.isLocked) {
          _paintLockedCell(canvas, rect, rrect, cell.lockLevel);
        } else if (cell.isFilled) {
          canvas.drawRRect(rrect, Paint()..color = blockColorToColor(cell.color!));
        } else if (_previewCells.contains(position)) {
          final previewColor = _previewValid ? Colors.white : Colors.redAccent;
          canvas.drawRRect(rrect, Paint()..color = previewColor.withValues(alpha: 0.35));
        } else {
          canvas.drawRRect(rrect, Paint()..color = const Color(0xFF262A3B));
        }
      }
    }
  }

  static const _lockedFill = Color(0xFF3A5A7A);
  static const _lockedBorder = Color(0xFFBBE3FF);

  void _paintLockedCell(Canvas canvas, Rect rect, RRect rrect, int lockLevel) {
    canvas.drawRRect(rrect, Paint()..color = _lockedFill);
    canvas.drawRRect(
      rrect,
      Paint()
        ..color = _lockedBorder.withValues(alpha: 0.7)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    final textPainter = TextPainter(
      text: TextSpan(
        text: '$lockLevel',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(
      canvas,
      rect.center - Offset(textPainter.width / 2, textPainter.height / 2),
    );
  }
}
