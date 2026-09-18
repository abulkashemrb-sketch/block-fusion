import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'screens/home_screen.dart';
import 'services/auth_service.dart';
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

  @override
  void dispose() {
    _authService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AuthScope(
      auth: _authService,
      child: MaterialApp(
        title: 'Block Fusion',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark,
        home: const HomeScreen(),
      ),
    );
  }
}

/// Makes the one [AuthService] reachable from any screen.
///
/// The app has exactly one of these and it lives for the whole session, so
/// an InheritedWidget is enough — no state-management package needed for a
/// single long-lived object.
class AuthScope extends InheritedWidget {
  const AuthScope({
    required this.auth,
    required super.child,
    super.key,
  });

  final AuthService auth;

  static AuthService of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AuthScope>();
    assert(scope != null, 'No AuthScope above this widget');
    return scope!.auth;
  }

  /// Returns null instead of asserting, for widgets that are also used in
  /// tests without an AuthScope around them.
  static AuthService? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AuthScope>()?.auth;

  @override
  bool updateShouldNotify(AuthScope oldWidget) => auth != oldWidget.auth;
}
