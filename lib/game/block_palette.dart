import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/block_color.dart';

/// Saturated candy colors — the face color of a block. The lighter top and
/// darker edge that give a block its depth are derived from these in
/// [paintBlockCell] rather than listed separately, so adding a color means
/// adding one entry here.
const Map<BlockColor, Color> _blockColorPalette = {
  BlockColor.red: Color(0xFFF5594E),
  BlockColor.orange: Color(0xFFF7922B),
  BlockColor.yellow: Color(0xFFF7C325),
  BlockColor.green: Color(0xFF5CC236),
  BlockColor.teal: Color(0xFF17C9B0),
  BlockColor.blue: Color(0xFF3B84F0),
  BlockColor.purple: Color(0xFF9B4DE0),
};

Color blockColorToColor(BlockColor color) => _blockColorPalette[color]!;

/// Paints one block cell as a rounded cube.
///
/// Three layers, drawn back to front: a darker rounded base that shows as
/// an edge all round and a thicker lip along the bottom; the lit face on
/// top of it, shaded from light at the top to the base color at the
/// bottom; and a small gloss cap. The whole thing is derived from [color]
/// so every block, tray piece and preview stays consistent.
void paintBlockCell(Canvas canvas, Rect rect, Color color) {
  final base = _shade(color, -0.16);
  final top = _shade(color, 0.18);

  canvas.drawRRect(
    RRect.fromRectAndRadius(rect, Radius.circular(rect.shortestSide * 0.26)),
    Paint()..color = base,
  );

  final face = Rect.fromLTRB(
    rect.left + rect.width * 0.08,
    rect.top + rect.height * 0.07,
    rect.right - rect.width * 0.08,
    rect.bottom - rect.height * 0.17,
  );
  if (face.isEmpty) return;

  canvas.drawRRect(
    RRect.fromRectAndRadius(face, Radius.circular(face.shortestSide * 0.26)),
    Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [top, color],
      ).createShader(face),
  );

  final gloss = Rect.fromLTWH(
    face.left + face.width * 0.14,
    face.top + face.height * 0.12,
    face.width * 0.36,
    face.height * 0.18,
  );
  if (gloss.isEmpty) return;
  canvas.drawRRect(
    RRect.fromRectAndRadius(gloss, Radius.circular(gloss.height / 2)),
    Paint()..color = Colors.white.withValues(alpha: 0.38),
  );
}

/// Every block color in order, with the first repeated at the end so a
/// sweep gradient closes without a seam.
final List<Color> _wildcardSweep = [
  ..._blockColorPalette.values,
  _blockColorPalette.values.first,
];

/// Paints a wildcard cell: a sweep through the whole palette with a star on
/// top. The sweep says "any color" at a glance, and the star keeps it
/// readable at tray scale, where the gradient alone is only a few pixels
/// wide.
void paintWildcardCell(Canvas canvas, Rect rect) {
  canvas.drawRRect(
    RRect.fromRectAndRadius(rect, Radius.circular(rect.shortestSide * 0.26)),
    Paint()
      ..shader = SweepGradient(colors: _wildcardSweep).createShader(rect),
  );
  _drawStar(canvas, rect.center, rect.shortestSide * 0.3);
}

/// Paints a bomb cell: a dark casing with a fused black sphere, so it reads
/// as "not a color" next to the candy blocks.
void paintBombCell(Canvas canvas, Rect rect) {
  final radius = Radius.circular(rect.shortestSide * 0.26);
  canvas
    ..drawRRect(
      RRect.fromRectAndRadius(rect, radius),
      Paint()..color = const Color(0xFF3A3352),
    )
    ..drawRRect(
      RRect.fromRectAndRadius(rect.deflate(rect.shortestSide * 0.09), radius),
      Paint()..color = const Color(0xFF221D33),
    )
    ..drawCircle(
      rect.center,
      rect.shortestSide * 0.28,
      Paint()..color = Colors.black,
    )
    ..drawCircle(
      rect.center,
      rect.shortestSide * 0.28,
      Paint()
        ..color = AppBombAccent.glow
        ..style = PaintingStyle.stroke
        ..strokeWidth = rect.shortestSide * 0.07,
    )
    ..drawCircle(
      rect.center - Offset(rect.width * 0.09, rect.height * 0.09),
      rect.shortestSide * 0.07,
      Paint()..color = Colors.white.withValues(alpha: 0.75),
    );
}

/// The one accent the bomb uses, named so it does not read as a stray hex
/// literal in the middle of the painter above.
abstract final class AppBombAccent {
  static const Color glow = Color(0xFFFF9F43);
}

void _drawStar(Canvas canvas, Offset center, double radius) {
  const points = 5;
  final path = Path();
  for (var i = 0; i < points * 2; i++) {
    // Start at the top so the star sits upright.
    final angle = -math.pi / 2 + i * math.pi / points;
    final r = i.isEven ? radius : radius * 0.45;
    final point = center + Offset(math.cos(angle) * r, math.sin(angle) * r);
    if (i == 0) {
      path.moveTo(point.dx, point.dy);
    } else {
      path.lineTo(point.dx, point.dy);
    }
  }
  path.close();

  canvas
    ..drawPath(path, Paint()..color = Colors.white)
    ..drawPath(
      path,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
}

Color _shade(Color color, double amount) {
  final hsl = HSLColor.fromColor(color);
  return hsl.withLightness((hsl.lightness + amount).clamp(0.0, 1.0)).toColor();
}
