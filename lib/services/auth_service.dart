import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_config.dart';

/// Signs the player in with Google and reports who is signed in.
///
/// A [ChangeNotifier] so screens can rebuild on sign-in and sign-out, in the
/// same way they already listen to [GameLogic]. It deliberately exposes only
/// what the UI needs — who the player is, whether a sign-in is in flight,
/// and what went wrong — rather than handing out the Supabase client.
///
/// The game is fully playable signed out. Every method here is a no-op when
/// [SupabaseConfig.isConfigured] is false, so a build with no backend
/// configured still runs instead of crashing on startup.
class AuthService extends ChangeNotifier {
  AuthService() {
    final auth = SupabaseConfig.maybeClient?.auth;
    if (auth == null) return;
    _auth = auth;
    _user = auth.currentUser;
    _subscription = auth.onAuthStateChange.listen(_onAuthStateChange);
  }

  /// Where Google sends the player back to after they approve.
  ///
  /// On the web this has to be an https origin, which only the running page
  /// knows, so it is left to the plugin's default (the current origin). On
  /// Android there is no origin, so the app claims a custom scheme — the
  /// matching intent filter is in AndroidManifest.xml, and the same string
  /// is registered as an allowed redirect on the Supabase project.
  static const String androidRedirect =
      'io.supabase.blockfusion://login-callback/';

  GoTrueClient? _auth;
  StreamSubscription<AuthState>? _subscription;

  User? _user;
  bool _isBusy = false;
  String? _errorMessage;

  /// Whether sign-in is available at all in this build.
  bool get isAvailable => _auth != null;

  User? get user => _user;
  bool get isSignedIn => _user != null;
  bool get isBusy => _isBusy;
  String? get errorMessage => _errorMessage;

  /// The player's name for display, falling back through what Google gave
  /// us and finally to the email local part.
  String get displayName {
    final metadata = _user?.userMetadata;
    final name = metadata?['full_name'] as String? ??
        metadata?['name'] as String? ??
        _user?.email?.split('@').first;
    return name ?? 'Player';
  }

  String? get avatarUrl => _user?.userMetadata?['avatar_url'] as String?;

  void _onAuthStateChange(AuthState state) {
    _user = state.session?.user;
    // A redirect back from Google lands here, not at the awaited call below,
    // so this is where a sign-in actually finishes.
    if (state.event == AuthChangeEvent.signedIn) {
      _isBusy = false;
      _errorMessage = null;
    }
    notifyListeners();
  }

  /// Opens Google's consent screen. Returns once the browser has been handed
  /// the request — not once the player has finished, which arrives later
  /// through [_onAuthStateChange].
  Future<void> signInWithGoogle() async {
    final auth = _auth;
    if (auth == null || _isBusy) return;

    _isBusy = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: kIsWeb ? null : androidRedirect,
      );
    } on AuthException catch (error) {
      _errorMessage = error.message;
      _isBusy = false;
      notifyListeners();
    } catch (error) {
      _errorMessage = 'Could not reach Google sign-in. Check your connection.';
      _isBusy = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    final auth = _auth;
    if (auth == null) return;
    try {
      await auth.signOut();
    } on AuthException catch (error) {
      _errorMessage = error.message;
      notifyListeners();
    }
  }

  void clearError() {
    if (_errorMessage == null) return;
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
