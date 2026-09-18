import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'screens/home_screen.dart';
import 'services/auth_service.dart';
import 'services/feedback_service.dart';
import 'services/supabase_config.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Sign-in and score sync are additions on top of the game, so a failure
  // to reach Supabase must not stop the app from starting. It runs signed
  // out instead, and AuthService reports itself unavailable.
  if (SupabaseConfig.isConfigured) {
    try {
      await Supabase.initialize(
        url: SupabaseConfig.url,
        publishableKey: SupabaseConfig.anonKey,
      );
    } catch (error) {
      debugPrint('Supabase.initialize failed, running offline: $error');
    }
  }

  runApp(const BlockFusionApp());
}

class BlockFusionApp extends StatefulWidget {
  const BlockFusionApp({super.key});

  @override
  State<BlockFusionApp> createState() => _BlockFusionAppState();
}

class _BlockFusionAppState extends State<BlockFusionApp> {
  late final AuthService _authService = AuthService();
  final FeedbackService _feedbackService = FeedbackService();

  @override
  void initState() {
    super.initState();
    _feedbackService.warmUp();
  }

  @override
  void dispose() {
    _authService.dispose();
    _feedbackService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScope(
      auth: _authService,
      feedback: _feedbackService,
      child: MaterialApp(
        title: 'Block Fusion',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark,
        home: const HomeScreen(),
      ),
    );
  }
}

/// Makes the app's long-lived services reachable from any screen.
///
/// There is exactly one of each and they live for the whole session, so an
/// InheritedWidget is enough — no state-management package needed to hand
/// around two objects that never get replaced.
class AppScope extends InheritedWidget {
  const AppScope({
    required this.auth,
    required this.feedback,
    required super.child,
    super.key,
  });

  final AuthService auth;
  final FeedbackService feedback;

  /// Returns null instead of asserting, because several screens are also
  /// pumped on their own in widget tests, with no scope above them.
  static AppScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppScope>();

  @override
  bool updateShouldNotify(AppScope oldWidget) =>
      auth != oldWidget.auth || feedback != oldWidget.feedback;
}
