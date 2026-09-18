import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'game_screen.dart';

/// Landing screen shown on app launch.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const _TitleBlocks(),
                  const SizedBox(height: 24),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      'BLOCK FUSION',
                      textAlign: TextAlign.center,
                      style:
                          Theme.of(context).textTheme.displayLarge?.copyWith(
                                fontSize: 42,
                                shadows: const [
                                  Shadow(
                                    color: Color(0x66000000),
                                    offset: Offset(0, 3),
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Fill lines. Fuse blocks. Beat your best score.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 48),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const GameScreen()),
                    ),
                    child: const Text('PLAY'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A small arrangement of blocks above the title, drawn with the same
/// cube styling the board uses so the menu and the game look like one game.
class _TitleBlocks extends StatelessWidget {
  const _TitleBlocks();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 168,
      height: 112,
      child: CustomPaint(painter: _TitleBlocksPainter()),
    );
  }
}

class _TitleBlocksPainter extends CustomPainter {
  /// Cells as (row, col, color index into the tile palette).
  static const List<(int, int, int)> _cells = [
    (0, 1, 0),
    (0, 2, 1),
    (1, 0, 2),
    (1, 1, 3),
    (1, 2, 4),
    (2, 2, 5),
  ];

  static const List<Color> _tileColors = [
    Color(0xFFF5594E),
    Color(0xFFF7C325),
    Color(0xFF3B84F0),
    Color(0xFF5CC236),
    Color(0xFF9B4DE0),
    Color(0xFF17C9B0),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final cell = size.width / 4;
    for (final (row, col, colorIndex) in _cells) {
      final rect = Rect.fromLTWH(
        col * cell + cell * 0.5,
        row * cell,
        cell,
        cell,
      ).deflate(cell * 0.06);
      _paintTile(canvas, rect, _tileColors[colorIndex]);
    }
  }

  /// A local copy of the board's cube look. The board's painter works on
  /// the Flame canvas; duplicating the few lines here keeps the menu from
  /// depending on the game layer.
  void _paintTile(Canvas canvas, Rect rect, Color color) {
    final hsl = HSLColor.fromColor(color);
    Color shade(double amount) =>
        hsl.withLightness((hsl.lightness + amount).clamp(0.0, 1.0)).toColor();

    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(rect.shortestSide * 0.26)),
      Paint()..color = shade(-0.16),
    );
    final face = Rect.fromLTRB(
      rect.left + rect.width * 0.08,
      rect.top + rect.height * 0.07,
      rect.right - rect.width * 0.08,
      rect.bottom - rect.height * 0.17,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(face, Radius.circular(face.shortestSide * 0.26)),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [shade(0.18), color],
        ).createShader(face),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
