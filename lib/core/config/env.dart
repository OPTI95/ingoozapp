import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Typed access to values declared in the `.env` file.
class Env {
  /// Base URL of the new Django REST API, e.g. `https://api.ingooz.ru`.
  /// All endpoints in [ApiEndpoints] are relative to this.
  static String get apiBaseUrl => _read('API_BASE_URL');

  // --- Legacy Supabase config (kept while old screens are not migrated) ---
  static String get supabaseUrl => _read('SUPABASE_URL');
  static String get supabaseAnonKey => _read('SUPABASE_ANON_KEY');

  static String _read(String key) {
    final value = dotenv.maybeGet(key);
    if (value == null || value.isEmpty) {
      throw Exception('Missing "$key" in .env file');
    }
    return value;
  }
}
