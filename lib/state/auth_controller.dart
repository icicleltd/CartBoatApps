import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/network/api_client.dart';
import '../core/storage/token_store.dart';
import '../data/models/user.dart';
import '../data/repositories/auth_repository.dart';

/// Signed-in user, or `null` for guests.
class AuthController extends AsyncNotifier<AppUser?> {
  AuthRepository get _repo => ref.read(authRepositoryProvider);
  TokenStore get _tokens => ref.read(tokenStoreProvider);

  @override
  Future<AppUser?> build() async {
    final token = await _tokens.load();
    if (token == null || token.isEmpty) return null;
    try {
      return await _repo.me();
    } on ApiException catch (e) {
      if (e.isUnauthorized) {
        await _tokens.clear();
        return null;
      }
      // Offline at launch: keep the session, we'll refresh later.
      return null;
    }
  }

  Future<AppUser?> login(String email, String password) async {
    final result = await _repo.login(email: email.trim(), password: password);
    await _tokens.save(result.token);
    AppUser? user = result.user;
    try {
      user = await _repo.me();
    } catch (_) {}
    state = AsyncData(user);
    return user;
  }

  Future<void> register({required String name, required String email, required String password}) async {
    await _repo.register(name: name.trim(), email: email.trim(), password: password);
    await login(email, password);
  }

  Future<void> refresh() async {
    if (_tokens.cached == null) return;
    try {
      state = AsyncData(await _repo.me());
    } on ApiException catch (e) {
      if (e.isUnauthorized) await logout();
    }
  }

  Future<void> logout() async {
    await _tokens.clear();
    state = const AsyncData(null);
  }
}

final authControllerProvider = AsyncNotifierProvider<AuthController, AppUser?>(AuthController.new);

/// Convenience: the current user (null while loading or signed out).
final currentUserProvider = Provider<AppUser?>((ref) => ref.watch(authControllerProvider).value);
final isSignedInProvider = Provider<bool>((ref) => ref.watch(currentUserProvider) != null);
