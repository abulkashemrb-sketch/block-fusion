import 'package:flutter/material.dart';

import 'game_screen.dart';

/// Landing screen shown on app launch.
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
    );
  }
}
