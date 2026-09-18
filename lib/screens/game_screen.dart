import 'dart:async';

import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../game/block_fusion_game.dart';
import '../logic/game_logic.dart';
import '../services/score_repository.dart';
import '../theme/app_theme.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late final GameLogic _logic = GameLogic();
  late final BlockFusionGame _game = BlockFusionGame(logic: _logic);
  final ScoreRepository _scores = ScoreRepository();

  /// Set once per run, so a game-over rebuild cannot post the same score
  /// again.
  bool _recordedThisRun = false;

  @override
  void initState() {
    super.initState();
    _logic.addListener(_onGameChanged);
    _loadBestScore();
  }

  /// Seeds the crown from the server, so a signed-in player's best score
  /// survives a reinstall or a move to another device.
  Future<void> _loadBestScore() async {
    final best = await _scores.fetchBestScore();
    if (best != null && mounted) _logic.raiseBestScore(best);
  }

  void _onGameChanged() {
    if (!_logic.isGameOver) {
      _recordedThisRun = false;
      return;
    }
    if (_recordedThisRun) return;
    _recordedThisRun = true;
    // Fire and forget: a failed sync must not cost the player their run,
    // and ScoreRepository already swallows and logs its own failures.
    unawaited(_scores.recordScore(_logic.score));
  }

  @override
  void dispose() {
    _logic.removeListener(_onGameChanged);
    _logic.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          // Every child here is positioned except the game-over builder,
          // which is an empty box while the game is running. Without an
          // explicit fit the stack shrink-wraps to that empty box, collapses
          // to zero size, and paints nothing at all.
          fit: StackFit.expand,
          children: [
            Positioned.fill(child: GameWidget(game: _game)),
            Positioned(
              top: 8,
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
                  bestScore: _logic.bestScore,
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

/// The crown-and-score readout: best score on a gold pill, current score as
/// the largest thing on screen.
class _ScoreHud extends StatelessWidget {
  const _ScoreHud({required this.logic});

  final GameLogic logic;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: logic,
      builder: (context, _) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _BestScorePill(bestScore: logic.bestScore),
          const SizedBox(height: 2),
          Text(
            '${logic.score}',
            key: const ValueKey('score-value'),
            style: const TextStyle(
              fontSize: 44,
              height: 1.1,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              shadows: [
                Shadow(
                  color: Color(0x66000000),
                  offset: Offset(0, 2),
                  blurRadius: 6,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BestScorePill extends StatelessWidget {
  const _BestScorePill({required this.bestScore});

  final int bestScore;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.emoji_events, color: AppTheme.accent, size: 16),
          const SizedBox(width: 5),
          Text(
            '$bestScore',
            style: const TextStyle(
              color: AppTheme.accent,
              fontWeight: FontWeight.w800,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

class _GameOverOverlay extends StatelessWidget {
  const _GameOverOverlay({
    required this.score,
    required this.bestScore,
    required this.onRestart,
  });

  final int score;
  final int bestScore;
  final VoidCallback onRestart;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withValues(alpha: 0.7),
        alignment: Alignment.center,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 32),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
          decoration: BoxDecoration(
            gradient: AppTheme.backgroundGradient,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'GAME OVER',
                style: Theme.of(context)
                    .textTheme
                    .displayLarge
                    ?.copyWith(fontSize: 30),
              ),
              const SizedBox(height: 20),
              Text(
                '$score',
                style: const TextStyle(
                  fontSize: 52,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 6),
              _BestScorePill(bestScore: bestScore),
              const SizedBox(height: 28),
              ElevatedButton(
                onPressed: onRestart,
                child: const Text('PLAY AGAIN'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
