/// Compile-time configuration for Supabase and the EcoWallet API.
///
/// Pass values via `--dart-define`:
/// ```bash
/// flutter run \
///   --dart-define=SUPABASE_URL=https://your-project.supabase.co \
///   --dart-define=SUPABASE_PUBLISHABLE_KEY=your-publishable-key \
///   # legacy alias: --dart-define=SUPABASE_ANON_KEY=your-key \
///   --dart-define=API_BASE_URL=http://127.0.0.1:3000
/// ```
abstract final class Env {
  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const supabasePublishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
  );
  static const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
  static const apiBaseUrl = String.fromEnvironment('API_BASE_URL');
  static const enablePushNotifications = bool.fromEnvironment(
    'ENABLE_PUSH_NOTIFICATIONS',
  );

  /// Supabase Flutter still names this parameter `anonKey`; use publishable key.
  static String get supabaseClientKey =>
      supabasePublishableKey.isNotEmpty
          ? supabasePublishableKey
          : supabaseAnonKey;

  static bool get isConfigured =>
      supabaseUrl.isNotEmpty && supabaseClientKey.isNotEmpty;

  static bool get isApiConfigured => apiBaseUrl.isNotEmpty;
}
