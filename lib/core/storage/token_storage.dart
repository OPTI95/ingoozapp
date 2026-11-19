import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Securely persists the JWT access/refresh pair returned by the API.
/// Backed by Keychain (iOS) / EncryptedSharedPreferences (Android).
class TokenStorage {
  TokenStorage(this._storage);

  final FlutterSecureStorage _storage;

  static const _kAccess = 'auth_access_token';
  static const _kRefresh = 'auth_refresh_token';

  // In-memory cache so the auth interceptor stays synchronous-fast.
  String? _accessCache;
  String? _refreshCache;

  Future<void> saveTokens({
    required String access,
    required String refresh,
  }) async {
    _accessCache = access;
    _refreshCache = refresh;
    await _storage.write(key: _kAccess, value: access);
    await _storage.write(key: _kRefresh, value: refresh);
  }

  Future<void> saveAccess(String access) async {
    _accessCache = access;
    await _storage.write(key: _kAccess, value: access);
  }

  Future<String?> readAccess() async {
    return _accessCache ??= await _storage.read(key: _kAccess);
  }

  Future<String?> readRefresh() async {
    return _refreshCache ??= await _storage.read(key: _kRefresh);
  }

  Future<bool> hasSession() async => (await readAccess()) != null;

  Future<void> clear() async {
    _accessCache = null;
    _refreshCache = null;
    await _storage.delete(key: _kAccess);
    await _storage.delete(key: _kRefresh);
  }
}
