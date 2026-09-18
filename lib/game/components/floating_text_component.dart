import 'package:flame/components.dart';
import 'package:flutter/material.dart';

/// A short-lived label that rises and fades — `+120`, `COMBO x3`,
/// `NEW BEST!`.
///
/// Rolled by hand rather than built from `TextComponent` plus effects
/// because the three things that have to move together here — position,
/// opacity and scale — are one curve, and chaining three effects to
/// reproduce it is more code and less legible than drawing it directly.
class FloatingTextComponent extends PositionComponent {
  FloatingTextComponent({
    required this.text,
    required this.color,
    required this.fontSize,
    required super.position,
    this.rise = 60,
    this.duration = 0.9,
    this.delay = 0,
    super.priority = 6,
  });

  final String text;
  final Color color;
  final double fontSize;

  /// How far the label travels upward over its life, in pixels.
  final double rise;
  final double duration;

  /// Held invisible for this long first, so several labels from one move
  /// can be staggered instead of stacking.
  final double delay;

  double _elapsed = 0;
  TextPainter? _painter;

  @override
  void onLoad() {
    _painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: FontWeight.w900,
          shadows: const [
            Shadow(color: Color(0xAA000000), offset: Offset(0, 2), blurRadius: 6),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
  }

  @override
  void update(double dt) {
    super.update(dt);
    _elapsed += dt;
    if (_elapsed >= delay + duration) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final painter = _painter;
    if (painter == null || _elapsed < delay) return;

    final t = ((_elapsed - delay) / duration).clamp(0.0, 1.0);

    // Pops up to full size in the first fifth, then holds — the label has
    // to be readable for most of its life, not growing throughout it.
    final scale = t < 0.2 ? 0.6 + (t / 0.2) * 0.5 : 1.1 - (t - 0.2) * 0.125;
    // Fades only over the last third, for the same reason.
    final opacity = t < 0.66 ? 1.0 : (1 - (t - 0.66) / 0.34).clamp(0.0, 1.0);

    canvas
      ..save()
      ..translate(0, -rise * t)
      ..translate(painter.width / 2, painter.height / 2)
      ..scale(scale)
      ..translate(-painter.width / 2, -painter.height / 2)
      ..saveLayer(
        Rect.fromLTWH(0, 0, painter.width, painter.height).inflate(20),
        Paint()..color = Colors.white.withValues(alpha: opacity),
      );
    painter.paint(canvas, Offset(-painter.width / 2, -painter.height / 2));
    canvas
      ..restore()
      ..restore();
  }
}
