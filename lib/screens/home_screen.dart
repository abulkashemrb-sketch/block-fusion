import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Landing screen shown on app launch.
///
/// This is intentionally a placeholder for now: the grid/board gameplay is
/// built in the next development phase and will be wired in behind the
/// "Play" action here.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'BLOCK FUSION',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                    fontSize: 40,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Fill lines. Fuse blocks. Beat your best score.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 48),
                ElevatedButton(
                  onPressed: null, // wired up once the game board ships
                  child: const Text('PLAY'),
                ),
                const SizedBox(height: 12),
                Text(
                  'Game board coming in the next step',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppTheme.muted),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
