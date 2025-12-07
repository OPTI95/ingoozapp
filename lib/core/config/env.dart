import 'package:flutter_dotenv/flutter_dotenv.dart';

class Env {
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

