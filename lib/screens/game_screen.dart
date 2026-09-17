import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../game/block_fusion_game.dart';
import '../logic/game_logic.dart';
import '../theme/app_theme.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late final GameLogic _logic = GameLogic();
  late final BlockFusionGame _game = BlockFusionGame(logic: _logic);

  @override
  void dispose() {
    _logic.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(child: GameWidget(game: _game)),
            Positioned(
              top: 12,
              left: 0,
              right: 0,
              child: _ScoreHud(logic: _logic),
            ),
            ListenableBuilder(
              listenable: _logic,
              builder: (context, _) {
                if (!_logic.isGameOver) return const SizedBox.shrink();
                return _GameOverOverlay(
                  score: _logic.score,
                  onRestart: _logic.restart,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ScoreHud extends StatelessWidget {
  const _ScoreHud({required this.logic});

  final GameLogic logic;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ListenableBuilder(
        listenable: logic,
        builder: (context, _) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            'SCORE  ${logic.score}',
            style: Theme.of(context)
                .textTheme
                .headlineMedium
                ?.copyWith(fontSize: 18),
          ),
        ),
      ),
    );
  }
}

class _GameOverOverlay extends StatelessWidget {
  const _GameOverOverlay({required this.score, required this.onRestart});

  final int score;
  final VoidCallback onRestart;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withValues(alpha: 0.75),
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'GAME OVER',
              style:
                  Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 32),
            ),
            const SizedBox(height: 12),
            Text('Score: $score', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 24),
            ElevatedButton(onPressed: onRestart, child: const Text('PLAY AGAIN')),
          ],
        ),
      ),
    );
  }
}
