/// API key dibaca dari --dart-define saat build/run.
///
/// Android Studio:
///   Run > Edit Configurations > Additional run args:
///   --dart-define=GEMINI_API_KEY=AIzaSy...key_kamu
///
/// Terminal:
///   flutter run --dart-define=GEMINI_API_KEY=AIzaSy...key_kamu
///
/// JANGAN hardcode key di sini dan jangan commit file yang berisi key.
class ApiConfig {
  static const String geminiApiKey = String.fromEnvironment(
    'GEMINI_API_KEY',
    defaultValue: '',
  );
}
