import 'dart:math';

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

/// The backdrop behind the board and tray: a vertical indigo-to-violet
/// gradient with a field of faint stars.
///
/// The stars are generated once from a fixed seed rather than per frame, so
/// they hold still instead of flickering, and regenerated only when the
/// canvas size actually changes.
class BackgroundComponent extends PositionComponent {
  BackgroundComponent() : super(priority: -10);

  static const int _starCount = 70;
  static const int _starSeed = 20260918;

  final List<_Star> _stars = [];

  void layout(Vector2 canvasSize) {
    if (size == canvasSize) return;
    size = canvasSize.clone();
    _generateStars();
  }

  void _generateStars() {
    final random = Random(_starSeed);
    _stars
      ..clear()
      ..addAll([
        for (var i = 0; i < _starCount; i++)
          _Star(
            offset: Offset(
              random.nextDouble() * size.x,
              random.nextDouble() * size.y,
            ),
            radius: 0.6 + random.nextDouble() * 1.4,
            opacity: 0.15 + random.nextDouble() * 0.45,
          ),
      ]);
  }

  @override
  void render(Canvas canvas) {
    final bounds = Rect.fromLTWH(0, 0, size.x, size.y);
    canvas.drawRect(
      bounds,
      Paint()..shader = AppTheme.backgroundGradient.createShader(bounds),
    );

    for (final star in _stars) {
      canvas.drawCircle(
        star.offset,
        star.radius,
        Paint()..color = Colors.white.withValues(alpha: star.opacity),
      );
    }
  }
}

class _Star {
  const _Star({
    required this.offset,
    required this.radius,
    required this.opacity,
  });

  final Offset offset;
  final double radius;
  final double opacity;
}
