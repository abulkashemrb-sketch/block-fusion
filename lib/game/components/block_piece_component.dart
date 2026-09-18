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
    required this.trayCellSize,
    required this.logic,
    required this.gridComponent,
  }) {
    _cellSize = trayCellSize;
    size = _sizeForCell(trayCellSize);
  }

  /// How far above the pointer the piece is held while dragging, in grid
  /// cells. Without it the finger covers the piece and the cells it is
  /// about to land on — the piece is smaller than a thumb on a phone.
  static const double _fingerLift = 1.2;

  final GameBlock block;
  final int trayIndex;

  /// The cell size the piece is drawn at while resting in the tray, which
  /// is deliberately smaller than a board cell so three pieces fit across.
  final double trayCellSize;

  final GameLogic logic;
  final GridComponent gridComponent;

  final Vector2 _homePosition = Vector2.zero();

  /// The cell size the piece is currently drawn at: [trayCellSize] at rest,
  /// and the board's cell size while dragging. Drop targeting always works
  /// in board cells, so a piece drawn at any other size while the player is
  /// aiming would not cover the cells it is about to fill.
  late double _cellSize;

  void setHome(Vector2 home) {
    _homePosition.setFrom(home);
    position = home.clone();
  }

  Vector2 _sizeForCell(double cellSize) =>
      Vector2(block.shape.width * cellSize, block.shape.height * cellSize);

  @override
  void onDragStart(DragStartEvent event) {
    super.onDragStart(event);
    priority = 10;

    final boardCellSize =
        gridComponent.cellSize > 0 ? gridComponent.cellSize : trayCellSize;
    final grabbed = event.localPosition;
    final trayBounds = size.clone();

    _cellSize = boardCellSize;
    size = _sizeForCell(boardCellSize);

    // Grow around the grabbed point rather than the top-left corner, so the
    // part of the piece under the finger stays under the finger, then lift
    // the whole piece clear of it.
    if (trayBounds.x > 0 && trayBounds.y > 0) {
      position.x -= (size.x - trayBounds.x) * (grabbed.x / trayBounds.x);
      position.y -= (size.y - trayBounds.y) * (grabbed.y / trayBounds.y);
    }
    position.y -= boardCellSize * _fingerLift;
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    position.add(event.localDelta);
    _updatePreview();
  }

  @override
  void onDragEnd(DragEndEvent event) {
    super.onDragEnd(event);
    gridComponent.clearPreview();

    final origin = _originUnderPointer();
    final placed = origin != null && logic.tryPlace(trayIndex, origin);
    if (!placed) _returnHome();
    // On success this component is torn down by TrayController's rebuild,
    // which runs synchronously inside logic.tryPlace above.
  }

  @override
  void onDragCancel(DragCancelEvent event) {
    super.onDragCancel(event);
    gridComponent.clearPreview();
    _returnHome();
  }

  void _returnHome() {
    priority = 0;
    _cellSize = trayCellSize;
    size = _sizeForCell(trayCellSize);
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
      block.previewOffsets,
      logic.canPlace(block, origin),
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
        offset.col * _cellSize,
        offset.row * _cellSize,
        _cellSize,
        _cellSize,
      ).deflate(_cellSize * 0.06);

      switch (block.kind) {
        case BlockKind.bomb:
          paintBombCell(canvas, rect);
        case BlockKind.wildcard:
          paintWildcardCell(canvas, rect);
        case BlockKind.normal:
          paintBlockCell(canvas, rect, blockColorToColor(block.color));
      }
    }
  }
}
