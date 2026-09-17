import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';

import '../../logic/game_logic.dart';
import '../../models/block_kind.dart';
import '../../models/game_block.dart';
import '../../models/grid_position.dart';
import '../block_palette.dart';
import 'grid_component.dart';

/// A draggable tray piece.
///
/// Lives directly under [BlockFusionGame] (a sibling of [GridComponent],
/// not a child of the tray) so its [position] shares the same coordinate
/// space as the grid, which the placement math below relies on.
class BlockPieceComponent extends PositionComponent with DragCallbacks {
  BlockPieceComponent({
    required this.block,
    required this.trayIndex,
    required this.cellSize,
    required this.logic,
    required this.gridComponent,
  }) {
    size = Vector2(block.shape.width * cellSize, block.shape.height * cellSize);
  }

  final GameBlock block;
  final int trayIndex;
  final double cellSize;
  final GameLogic logic;
  final GridComponent gridComponent;

  final Vector2 _homePosition = Vector2.zero();

  void setHome(Vector2 home) {
    _homePosition.setFrom(home);
    position = home.clone();
  }

  @override
  void onDragStart(DragStartEvent event) {
    super.onDragStart(event);
    priority = 10;
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    position.add(event.localDelta);
    _updatePreview();
  }

  @override
  void onDragEnd(DragEndEvent event) {
    super.onDragEnd(event);
    priority = 0;
    gridComponent.clearPreview();

    final origin = _originUnderPointer();
    final placed = origin != null && logic.tryPlace(trayIndex, origin);
    if (!placed) {
      position = _homePosition.clone();
    }
    // On success this component is torn down by TrayController's rebuild,
    // which runs synchronously inside logic.tryPlace above.
  }

  @override
  void onDragCancel(DragCancelEvent event) {
    super.onDragCancel(event);
    priority = 0;
    gridComponent.clearPreview();
    position = _homePosition.clone();
  }

  void _updatePreview() {
    final origin = _originUnderPointer();
    if (origin == null) {
      gridComponent.clearPreview();
      return;
    }
    gridComponent.setPreview(
      origin,
      block.shape.cells,
      logic.grid.canPlace(block.shape, origin),
    );
  }

  /// The grid cell the shape's top-left corner would land on if dropped
  /// now, or `null` if any of its cells would fall off the board.
  GridPosition? _originUnderPointer() {
    if (gridComponent.cellSize <= 0) return null;

    final localX = position.x - gridComponent.position.x;
    final localY = position.y - gridComponent.position.y;
    final origin = GridPosition(
      (localY / gridComponent.cellSize).round(),
      (localX / gridComponent.cellSize).round(),
    );

    for (final offset in block.shape.cells) {
      if (!logic.grid.isInBounds(origin + offset)) return null;
    }
    return origin;
  }

  @override
  void render(Canvas canvas) {
    for (final offset in block.shape.cells) {
      final rect = Rect.fromLTWH(
        offset.col * cellSize,
        offset.row * cellSize,
        cellSize,
        cellSize,
      ).deflate(2);
      final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(6));

      if (block.kind == BlockKind.bomb) {
        _paintBomb(canvas, rect, rrect);
      } else {
        canvas.drawRRect(rrect, Paint()..color = blockColorToColor(block.color));
      }
    }
  }

  void _paintBomb(Canvas canvas, Rect rect, RRect rrect) {
    canvas.drawRRect(rrect, Paint()..color = const Color(0xFF2B2B33));
    canvas.drawCircle(rect.center, rect.shortestSide * 0.32, Paint()..color = Colors.black);
    canvas.drawCircle(
      rect.center,
      rect.shortestSide * 0.32,
      Paint()
        ..color = Colors.orangeAccent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }
}
