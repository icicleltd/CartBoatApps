import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Persists the access token in the platform keystore and keeps an in-memory
/// copy so request interceptors can read it synchronously.
class TokenStore {
  TokenStore([FlutterSecureStorage? storage]) : _storage = storage ?? const FlutterSecureStorage();

  static const _key = 'cb_access_token';
  final FlutterSecureStorage _storage;
  String? _cached;

  String? get cached => _cached;

  Future<String?> load() async {
    try {
      _cached = await _storage.read(key: _key);
    } catch (_) {
      _cached = null;
    }
    return _cached;
  }

  Future<void> save(String token) async {
    _cached = token;
    try {
      await _storage.write(key: _key, value: token);
    } catch (_) {}
  }

  Future<void> clear() async {
    _cached = null;
    try {
      await _storage.delete(key: _key);
    } catch (_) {}
  }
}

final tokenStoreProvider = Provider<TokenStore>((ref) => TokenStore());
