import 'package:flame/game.dart';

import '../../logic/game_logic.dart';
import 'block_piece_component.dart';
import 'grid_component.dart';

/// Keeps the draggable tray pieces in sync with [GameLogic.tray].
///
/// This is a plain controller, not a [Component]: its pieces are added
/// directly to [game] so their coordinates share the same space as
/// [GridComponent] (see [BlockPieceComponent]'s doc comment).
class TrayController {
  TrayController({
    required this.game,
    required this.logic,
    required this.gridComponent,
  }) {
    logic.addListener(_rebuild);
  }

  final FlameGame game;
  final GameLogic logic;
  final GridComponent gridComponent;

  Vector2 _canvasSize = Vector2.zero();

  void layout(Vector2 canvasSize) {
    _canvasSize = canvasSize;
    _rebuild();
  }

  void dispose() {
    logic.removeListener(_rebuild);
  }

  void _rebuild() {
    for (final piece in game.children.whereType<BlockPieceComponent>().toList()) {
      piece.removeFromParent();
    }
    if (_canvasSize.x == 0 && _canvasSize.y == 0) return;

    final slotCount = logic.tray.length;
    final slotWidth = _canvasSize.x / slotCount;
    final trayCenterY = _canvasSize.y * 0.8;
    final pieceCellSize =
        gridComponent.cellSize > 0 ? gridComponent.cellSize * 0.65 : 24.0;

    for (var i = 0; i < slotCount; i++) {
      final block = logic.tray[i];
      if (block == null) continue;

      final piece = BlockPieceComponent(
        block: block,
        trayIndex: i,
        cellSize: pieceCellSize,
        logic: logic,
        gridComponent: gridComponent,
      );
      final slotCenterX = slotWidth * i + slotWidth / 2;
      piece.setHome(Vector2(
        slotCenterX - piece.size.x / 2,
        trayCenterY - piece.size.y / 2,
      ));
      game.add(piece);
    }
  }
}
