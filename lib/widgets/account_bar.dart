import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../theme/app_theme.dart';

/// The sign-in row on the home screen.
///
/// Shows a Google sign-in button when signed out and the player's name with
/// a sign-out action when signed in. Renders nothing at all when the build
/// has no backend configured, so a game without Supabase does not advertise
/// a button that cannot work.
class AccountBar extends StatelessWidget {
  const AccountBar({required this.auth, super.key});

  final AuthService auth;

  @override
  Widget build(BuildContext context) {
    if (!auth.isAvailable) return const SizedBox.shrink();

    return ListenableBuilder(
      listenable: auth,
      builder: (context, _) {
        final error = auth.errorMessage;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (auth.isSignedIn)
              _SignedIn(auth: auth)
            else
              _SignInButton(auth: auth),
            if (error != null) ...[
              const SizedBox(height: 10),
              _ErrorNote(message: error, onDismiss: auth.clearError),
            ],
          ],
        );
      },
    );
  }
}

class _SignInButton extends StatelessWidget {
  const _SignInButton({required this.auth});

  final AuthService auth;

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: auth.isBusy ? null : auth.signInWithGoogle,
      style: TextButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: Colors.white.withValues(alpha: 0.12),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      icon: auth.isBusy
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : const Icon(Icons.login, size: 18),
      label: Text(
        auth.isBusy ? 'Opening Google…' : 'Sign in with Google',
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _SignedIn extends StatelessWidget {
  const _SignedIn({required this.auth});

  final AuthService auth;

  @override
  Widget build(BuildContext context) {
    final avatarUrl = auth.avatarUrl;
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 6, 4, 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 14,
            backgroundColor: AppTheme.primary,
            backgroundImage:
                avatarUrl != null ? NetworkImage(avatarUrl) : null,
            child: avatarUrl == null
                ? Text(
                    auth.displayName.characters.first.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 10),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 160),
            child: Text(
              auth.displayName,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          IconButton(
            onPressed: auth.signOut,
            icon: const Icon(Icons.logout, size: 18),
            color: AppTheme.muted,
            tooltip: 'Sign out',
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}

class _ErrorNote extends StatelessWidget {
  const _ErrorNote({required this.message, required this.onDismiss});

  final String message;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onDismiss,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        constraints: const BoxConstraints(maxWidth: 300),
        decoration: BoxDecoration(
          color: const Color(0xFFFF6B6B).withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 12, color: Color(0xFFFFD4D4)),
        ),
      ),
    );
  }
}
