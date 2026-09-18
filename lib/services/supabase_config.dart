import 'package:supabase_flutter/supabase_flutter.dart';

/// Where the app's Supabase project lives.
///
/// Both values are read at compile time from `--dart-define`, with the real
/// project's values as defaults so a plain `flutter run` works. They are
/// safe to ship: this key (Supabase now calls it the publishable key) is
/// designed to reach every client, and Row Level Security — not the secrecy
/// of the key — is what protects the data. The service_role key must never
/// appear here or anywhere else in this codebase.

abstract final class SupabaseConfig {
  static const String url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://rnodpvkbqmzusgeapwiy.supabase.co',
  );

  static const String anonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJub2RwdmticW16dXNnZWFwd2l5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODk3NDMwODAsImV4cCI6MjEwNTMxOTA4MH0.TO5n5ca4ntSTXTLyKb0SZuuizxABaU99hDzuuww5sHw',
  );

  /// The OAuth client id Google issues for the web build. Android reads its
  /// client id from the google-services configuration instead, so this is
  /// only consulted on the web.
  static const String googleWebClientId = String.fromEnvironment(
    'GOOGLE_WEB_CLIENT_ID',
    defaultValue: '',
  );

  /// Whether the app has enough configuration to talk to Supabase at all.
  ///
  /// The game is playable without it — sign-in and score sync are the only
  /// things that need a backend — so every caller checks this instead of
  /// assuming a client exists.
  static bool get isConfigured => url.isNotEmpty && anonKey.isNotEmpty;

  /// The live client, or `null` when there is none to hand out.
  ///
  /// `Supabase.instance` *asserts* rather than returning null when
  /// initialization never ran or failed, which would take the whole app down
  /// over an optional feature — and does so in widget tests, which never
  /// call `main()`. Every caller goes through here instead of touching
  /// `Supabase.instance` directly.
  static SupabaseClient? get maybeClient {
    if (!isConfigured) return null;
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }
}
