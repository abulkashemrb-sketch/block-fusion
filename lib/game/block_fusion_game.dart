import 'package:flame/game.dart';
import 'package:flutter/material.dart' show Color;

import '../logic/game_logic.dart';
import '../theme/app_theme.dart';
import 'components/background_component.dart';
import 'components/effects_controller.dart';
import 'components/grid_component.dart';
import 'components/tray_controller.dart';

/// The Flame game hosting the board and tray for a single match.
class BlockFusionGame extends FlameGame {
  BlockFusionGame({required this.logic});

  final GameLogic logic;

  BackgroundComponent? _background;
  GridComponent? _gridComponent;
  TrayController? _trayController;
  EffectsController? _effectsController;

  // The gradient backdrop is a component so it can carry the star field;
  // this flat colour only shows for the frame before it mounts.
  @override
  Color backgroundColor() => AppTheme.background;

  @override
  Future<void> onLoad() async {
    final background = BackgroundComponent();
    add(background);
    _background = background;

    final gridComponent = GridComponent(logic: logic);
    // Do not await: add() completes when the component is mounted, and
    // mounting is processed by the game loop, which does not run until
    // onLoad() returns. Awaiting here deadlocks and the game never loads.
    add(gridComponent);
    _gridComponent = gridComponent;
    _trayController = TrayController(
      game: this,
      logic: logic,
      gridComponent: gridComponent,
    );
    _effectsController = EffectsController(
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
    _background?.layout(canvasSize);
    _gridComponent?.layout(canvasSize);
    _trayController?.layout(canvasSize);
  }

  @override
  void onRemove() {
    _effectsController?.dispose();
    _trayController?.dispose();
    super.onRemove();
  }
}
