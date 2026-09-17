import 'package:flame/game.dart';
import 'package:flutter/material.dart' show Color;

import '../logic/game_logic.dart';
import 'components/grid_component.dart';
import 'components/tray_controller.dart';

/// The Flame game hosting the board and tray for a single match.
class BlockFusionGame extends FlameGame {
  BlockFusionGame({required this.logic});

  final GameLogic logic;

  GridComponent? _gridComponent;
  TrayController? _trayController;

  @override
  Color backgroundColor() => const Color(0xFF12141C);

  @override
  Future<void> onLoad() async {
    final gridComponent = GridComponent(logic: logic);
    await add(gridComponent);
    _gridComponent = gridComponent;
    _trayController = TrayController(
      game: this,
      logic: logic,
      gridComponent: gridComponent,
    );
    _layout(size);
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    _layout(size);
  }

  void _layout(Vector2 canvasSize) {
    _gridComponent?.layout(canvasSize);
    _trayController?.layout(canvasSize);
  }

  @override
  void onRemove() {
    _trayController?.dispose();
    super.onRemove();
  }
}
