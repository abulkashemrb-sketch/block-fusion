import 'package:flutter/material.dart';

import '../game/block_palette.dart';
import '../services/feedback_service.dart';
import '../theme/app_theme.dart';

/// Sound and vibration switches, and an explanation of the pieces.
///
/// The explanation lives here rather than in a first-run tutorial because
/// the special pieces are rare: by the time a bomb turns up, a tutorial
/// shown at launch has long been forgotten, and a player who wants to know
/// what the rainbow block does needs somewhere to look it up.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({required this.feedback, super.key});

  final FeedbackService feedback;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('SETTINGS')),
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              ListenableBuilder(
                listenable: feedback,
                builder: (context, _) => Column(
                  children: [
                    _Toggle(
                      icon: Icons.volume_up,
                      label: 'Sound',
                      value: feedback.soundEnabled,
                      onChanged: feedback.setSoundEnabled,
                    ),
                    const SizedBox(height: 10),
                    _Toggle(
                      icon: Icons.vibration,
                      label: 'Vibration',
                      value: feedback.hapticsEnabled,
                      onChanged: feedback.setHapticsEnabled,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              Text(
                'HOW TO PLAY',
                style: Theme.of(context)
                    .textTheme
                    .headlineMedium
                    ?.copyWith(fontSize: 16, letterSpacing: 1.2),
              ),
              const SizedBox(height: 12),
              const _Rule(
                title: 'Fill a line',
                body: 'Drag pieces onto the board. Complete a row or a column '
                    'and it clears. Clear two or more at once and the combo '
                    'multiplies what you score.',
              ),
              const _Rule(
                title: 'One colour, double points',
                body: 'If every coloured cell in a cleared line is the same '
                    'colour, that line is worth twice as much.',
              ),
              _Rule(
                title: 'Wildcard',
                swatch: const _WildcardSwatch(),
                body: 'Counts as whatever colour the line around it is, so it '
                    'can finish a single-colour line you could not otherwise '
                    'complete.',
              ),
              _Rule(
                title: 'Bomb',
                swatch: const _BombSwatch(),
                body: 'Drops on any cell, full or empty, and clears the 3x3 '
                    'around it — including locked cells. Save it for when the '
                    'board jams.',
              ),
              _Rule(
                title: 'Locked cell',
                swatch: const _LockedSwatch(),
                body: 'Blocks placement but still counts towards completing a '
                    'line. Each clear that crosses it takes one level off; two '
                    'clears break it open.',
              ),
              const SizedBox(height: 8),
              Text(
                'The game ends when none of the three pieces fits anywhere.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _Toggle extends StatelessWidget {
  const _Toggle({
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.muted, size: 20),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppTheme.accent,
          ),
        ],
      ),
    );
  }
}

class _Rule extends StatelessWidget {
  const _Rule({required this.title, required this.body, this.swatch});

  final String title;
  final String body;
  final Widget? swatch;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 44,
            child: swatch ?? const SizedBox.shrink(),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(body, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The swatches paint the real thing, using the same painters the board
/// does, so the explanation cannot drift out of step with the game.
class _Swatch extends StatelessWidget {
  const _Swatch(this.painter);

  final CustomPainter painter;

  @override
  Widget build(BuildContext context) =>
      SizedBox(width: 32, height: 32, child: CustomPaint(painter: painter));
}

class _WildcardSwatch extends StatelessWidget {
  const _WildcardSwatch();

  @override
  Widget build(BuildContext context) => _Swatch(_CellPainter(paintWildcardCell));
}

class _BombSwatch extends StatelessWidget {
  const _BombSwatch();

  @override
  Widget build(BuildContext context) => _Swatch(_CellPainter(paintBombCell));
}

class _LockedSwatch extends StatelessWidget {
  const _LockedSwatch();

  @override
  Widget build(BuildContext context) => _Swatch(
        _CellPainter(
          (canvas, rect) {
            final rrect = RRect.fromRectAndRadius(
              rect,
              Radius.circular(rect.shortestSide * 0.26),
            );
            canvas
              ..drawRRect(rrect, Paint()..color = const Color(0xFF4B6E93))
              ..drawRRect(
                rrect,
                Paint()
                  ..color = const Color(0xFFBBE3FF)
                  ..style = PaintingStyle.stroke
                  ..strokeWidth = rect.shortestSide * 0.08,
              );
          },
        ),
      );
}

class _CellPainter extends CustomPainter {
  const _CellPainter(this.draw);

  final void Function(Canvas canvas, Rect rect) draw;

  @override
  void paint(Canvas canvas, Size size) =>
      draw(canvas, Offset.zero & size);

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
