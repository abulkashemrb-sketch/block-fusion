import 'dart:async';

import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../game/block_fusion_game.dart';
import '../logic/game_logic.dart';
import '../main.dart';
import '../services/feedback_service.dart';
import '../services/game_storage.dart';
import '../services/score_repository.dart';
import '../theme/app_theme.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late final GameLogic _logic = GameLogic();
  late final BlockFusionGame _game = BlockFusionGame(
    logic: _logic,
    feedback: _feedback,
  );
  final ScoreRepository _scores = ScoreRepository();
  final GameStorage _storage = GameStorage();

  /// The app-wide service when there is one, and a local instance when the
  /// screen is pumped on its own in a test.
  late final FeedbackService _feedback =
      AppScope.maybeOf(context)?.feedback ?? FeedbackService();

  /// Set once per run, so a game-over rebuild cannot post the same score
  /// again.
  bool _recordedThisRun = false;

  /// Held until the saved game has been read, so the first move cannot save
  /// a fresh board over the one still being restored.
  bool _restored = false;

  /// What became of the score this run, shown on the game-over card. Null
  /// while the request is still in flight.
  SyncOutcome? _syncOutcome;

  @override
  void initState() {
    super.initState();
    _logic.addListener(_onGameChanged);
    _resume();
  }

  /// Puts the player back where they left off, then raises the crown to
  /// whatever the device and the server remember.
  Future<void> _resume() async {
    final saved = await _storage.loadGame();
    if (!mounted) return;
    if (saved != null) _logic.restore(saved);

    final localBest = await _storage.loadBestScore();
    if (!mounted) return;
    _logic.raiseBestScore(localBest);
    _restored = true;

    // The server's copy arrives last and can only raise the crown further,
    // so a slow network never shows a lower number than the device knows.
    final remoteBest = await _scores.fetchBestScore();
    if (remoteBest != null && mounted) _logic.raiseBestScore(remoteBest);
  }

  void _onGameChanged() {
    if (!_restored) return;

    if (!_logic.isGameOver) {
      _recordedThisRun = false;
      _syncOutcome = null;
      unawaited(_storage.saveGame(_logic.toSnapshot()));
      return;
    }
    if (_recordedThisRun) return;
    _recordedThisRun = true;

    // The run is over, so there is nothing to resume — but the best score
    // it may have set still has to survive.
    unawaited(_storage.clearGame());
    unawaited(_storage.saveBestScore(_logic.bestScore));
    unawaited(_syncScore());
  }

  /// Sends the score and remembers how it went, so the game-over card can
  /// say so instead of leaving the player guessing.
  Future<void> _syncScore() async {
    final outcome = await _scores.recordScore(_logic.score);
    if (mounted) setState(() => _syncOutcome = outcome);
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
                  syncOutcome: _syncOutcome,
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
    required this.syncOutcome,
    required this.onRestart,
  });

  final int score;
  final int bestScore;
  final SyncOutcome? syncOutcome;
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
              const SizedBox(height: 14),
              _SyncNote(outcome: syncOutcome),
              const SizedBox(height: 20),
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

/// One line on the game-over card saying what became of the score.
///
/// Silence here used to be ambiguous: a player who was not signed in and a
/// player whose request failed saw exactly the same thing as one whose
/// score had saved fine.
class _SyncNote extends StatelessWidget {
  const _SyncNote({required this.outcome});

  final SyncOutcome? outcome;

  @override
  Widget build(BuildContext context) {
    final (icon, message, color) = switch (outcome) {
      null => (Icons.cloud_upload, 'Saving your score…', AppTheme.muted),
      SyncOutcome.saved => (
          Icons.cloud_done,
          'Score saved',
          AppTheme.secondary,
        ),
      SyncOutcome.notSignedIn => (
          Icons.cloud_off,
          'Sign in to save your score',
          AppTheme.muted,
        ),
      SyncOutcome.nothingToSave => (
          Icons.remove,
          'Nothing to save this round',
          AppTheme.muted,
        ),
      SyncOutcome.failed => (
          Icons.cloud_off,
          'Could not save — check your connection',
          Color(0xFFFFB4B4),
        ),
    };

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: color),
        const SizedBox(width: 7),
        Flexible(
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: color),
          ),
        ),
      ],
    );
  }
}
