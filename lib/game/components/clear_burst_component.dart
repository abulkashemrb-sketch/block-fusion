import 'dart:math';

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../block_palette.dart';

/// A cleared cell, bursting.
///
/// The board is drawn straight from the logic state, so by the time a clear
/// is rendered the cell is already empty — this component is the block's
/// afterimage, added on top of the board and given a short life of its own.
/// It draws the same cube the board does, throws a handful of shards out of
/// it, and removes itself when the animation ends.
///
/// Spawned as a child of GridComponent, so its [position] is in board-local
/// coordinates like every cell rect.
class ClearBurstComponent extends PositionComponent {
  ClearBurstComponent({
    required this.color,
    required this.cellSize,
    required super.position,
    int seed = 0,
  })  : _random = Random(seed),
        super(size: Vector2.all(cellSize), priority: 5);

  static const double _duration = 0.38;
  static const int _shardCount = 6;

  final Color color;
  final double cellSize;
  final Random _random;

  late final List<_Shard> _shards = [
    for (var i = 0; i < _shardCount; i++)
      _Shard(
        // Fan the shards out evenly and then jitter, so a burst reads as a
        // burst rather than a ring.
        angle: (i / _shardCount) * 2 * pi + _random.nextDouble() * 0.8,
        speed: cellSize * (1.4 + _random.nextDouble() * 1.6),
        size: cellSize * (0.12 + _random.nextDouble() * 0.12),
      ),
  ];

  double _elapsed = 0;

  /// 0 at the start, 1 at the end.
  double get _t => (_elapsed / _duration).clamp(0.0, 1.0);

  @override
  void update(double dt) {
    super.update(dt);
    _elapsed += dt;
    if (_elapsed >= _duration) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final t = _t;

    // The block itself: a quick swell, then shrink away. Overshooting
    // before it collapses is what makes it read as a pop rather than a
    // fade.
    final scale = t < 0.25 ? 1 + t * 0.9 : 1.225 - (t - 0.25) * 1.63;
    if (scale > 0) {
      final side = cellSize * scale;
      final rect = Rect.fromCenter(
        center: Offset(cellSize / 2, cellSize / 2),
        width: side,
        height: side,
      ).deflate(cellSize * 0.06 * scale);
      if (!rect.isEmpty) {
        canvas.saveLayer(
          rect.inflate(cellSize),
          Paint()..color = Colors.white.withValues(alpha: (1 - t).clamp(0.0, 1.0)),
        );
        paintBlockCell(canvas, rect, color);
        canvas.restore();
      }
    }

    // Shards fly out, slow down, and fade.
    final shardPaint = Paint()
      ..color = color.withValues(alpha: ((1 - t) * 0.9).clamp(0.0, 1.0));
    final travel = 1 - (1 - t) * (1 - t); // ease out
    for (final shard in _shards) {
      final distance = shard.speed * travel * _duration;
      final center = Offset(
        cellSize / 2 + cos(shard.angle) * distance,
        cellSize / 2 + sin(shard.angle) * distance,
      );
      final side = shard.size * (1 - t);
      if (side <= 0) continue;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: center, width: side, height: side),
          Radius.circular(side * 0.3),
        ),
        shardPaint,
      );
    }
  }
}

class _Shard {
  const _Shard({
    required this.angle,
    required this.speed,
    required this.size,
  });

  final double angle;
  final double speed;
  final double size;
}
