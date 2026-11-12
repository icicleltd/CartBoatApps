import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_client.dart';
import '../../core/utils/json.dart';
import '../models/user.dart';

class LoginResult {
  const LoginResult(this.user, this.token);
  final AppUser? user;
  final String token;
}

class AuthRepository {
  AuthRepository(this._api);
  final ApiClient _api;

  Future<LoginResult> login({required String email, required String password}) async {
    final res = await _api.post('/auth/login', body: {'email': email, 'password': password});
    final data = asJson(res['data']);
    final token = str(pick(data, ['accessToken', 'token', 'access_token']));
    if (token.isEmpty) throw ApiException('Sign in failed. Please try again.');
    final userJson = asJson(data['user']);
    return LoginResult(userJson.isEmpty ? null : AppUser.fromJson(userJson), token);
  }

  Future<AppUser> me() async {
    final res = await _api.get('/auth/me');
    return AppUser.fromJson(asJson(res['data']));
  }

  Future<String> register({required String name, required String email, required String password}) async {
    final res = await _api.post('/users', body: {'name': name, 'email': email, 'password': password});
    return str(res['message'], 'Account created');
  }

  Future<String> becomeSeller({
    required String name,
    required String email,
    required String shopName,
    required String password,
  }) async {
    final res = await _api.post(
      '/auth/be-seller',
      body: {'name': name, 'email': email, 'shopName': shopName, 'password': password},
    );
    return str(res['message'], 'We sent a verification code to your email');
  }

  Future<String> verifySellerOtp({required String email, required String otp}) async {
    final res = await _api.post('/auth/be-seller-otp', body: {'email': email, 'otp': otp});
    return str(res['message'], 'Verified');
  }

  Future<String> resendOtp(String email) async {
    final res = await _api.post('/auth/resend-otp', body: {'email': email});
    return str(res['message'], 'A new code is on its way');
  }
}

final authRepositoryProvider = Provider((ref) => AuthRepository(ref.watch(apiClientProvider)));
