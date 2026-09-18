import 'package:flutter/material.dart';

import '../models/leaderboard_entry.dart';
import '../services/score_repository.dart';
import '../theme/app_theme.dart';

/// The top players by best score.
///
/// Reads `profiles`, which every signed-in player can select — a player's
/// individual games stay private to them.
class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({this.repository, this.currentUserId, super.key});

  /// Injectable so a widget test can supply rows without a backend.
  final ScoreRepository? repository;

  /// Highlights the signed-in player's own row, when there is one.
  final String? currentUserId;

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  late final ScoreRepository _repository =
      widget.repository ?? ScoreRepository();
  late Future<List<LeaderboardEntry>> _entries = _repository.fetchLeaderboard();

  void _reload() {
    setState(() => _entries = _repository.fetchLeaderboard());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('LEADERBOARD'),
        actions: [
          IconButton(
            onPressed: _reload,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
        child: SafeArea(
          child: FutureBuilder<List<LeaderboardEntry>>(
            future: _entries,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final entries = snapshot.data ?? const <LeaderboardEntry>[];
              if (entries.isEmpty) {
                return const _EmptyState();
              }
              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: entries.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, index) => _Row(
                  rank: index + 1,
                  entry: entries[index],
                  isCurrentUser: entries[index].userId == widget.currentUserId,
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 40),
        child: Text(
          'No scores yet.\nSign in and play a game to claim the top spot.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppTheme.muted, height: 1.5),
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.rank,
    required this.entry,
    required this.isCurrentUser,
  });

  final int rank;
  final LeaderboardEntry entry;
  final bool isCurrentUser;

  /// Gold, silver and bronze for the top three; the normal accent below.
  static const List<Color> _medals = [
    Color(0xFFFFCB3D),
    Color(0xFFCFD6E4),
    Color(0xFFD9915A),
  ];

  Color get _rankColor =>
      rank <= _medals.length ? _medals[rank - 1] : AppTheme.muted;

  @override
  Widget build(BuildContext context) {
    final avatarUrl = entry.avatarUrl;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: isCurrentUser ? 0.18 : 0.08),
        borderRadius: BorderRadius.circular(16),
        border: isCurrentUser
            ? Border.all(color: AppTheme.accent.withValues(alpha: 0.6))
            : null,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Text(
              '$rank',
              style: TextStyle(
                color: _rankColor,
                fontWeight: FontWeight.w900,
                fontSize: 16,
              ),
            ),
          ),
          CircleAvatar(
            radius: 16,
            backgroundColor: AppTheme.primary,
            backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
            child: avatarUrl == null
                ? Text(
                    entry.displayName.characters.first.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              entry.displayName,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          Text(
            '${entry.bestScore}',
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 17,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
