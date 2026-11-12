import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/env.dart';
import '../storage/token_store.dart';

/// A user-presentable API failure.
class ApiException implements Exception {
  ApiException(this.message, {this.statusCode, this.fieldErrors = const {}});

  final String message;
  final int? statusCode;
  final Map<String, String> fieldErrors;

  bool get isUnauthorized => statusCode == 401;
  bool get isNetwork => statusCode == null;

  static ApiException from(Object error) {
    if (error is ApiException) return error;
    if (error is DioException) {
      final data = error.response?.data;
      final status = error.response?.statusCode;
      if (data is Map) {
        final fields = <String, String>{};
        final errors = data['errors'];
        if (errors is List) {
          for (final e in errors) {
            if (e is Map && e['message'] != null) {
              final field = (e['field'] ?? e['path'] ?? '').toString().split('.').last;
              fields[field] = e['message'].toString();
            }
          }
        }
        var message = (data['message'] ?? '').toString();
        if (message.isEmpty || message == 'Validation failed') {
          message = fields.values.isNotEmpty ? fields.values.first : (message.isEmpty ? _fallback(status) : message);
        }
        return ApiException(message, statusCode: status, fieldErrors: fields);
      }
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.receiveTimeout:
        case DioExceptionType.sendTimeout:
          return ApiException('The connection timed out. Please try again.');
        case DioExceptionType.connectionError:
          return ApiException('You appear to be offline. Check your connection and try again.');
        default:
          return ApiException(_fallback(status), statusCode: status);
      }
    }
    return ApiException('Something went wrong. Please try again.');
  }

  static String _fallback(int? status) => switch (status) {
    401 => 'Please sign in to continue.',
    403 => 'You don\'t have access to this.',
    404 => 'We couldn\'t find what you were looking for.',
    _ => 'Something went wrong. Please try again.',
  };

  @override
  String toString() => message;
}

/// Thin wrapper around Dio that unwraps the backend's
/// `{ success, message, data, pagination }` envelope.
class ApiClient {
  ApiClient(this._dio);

  final Dio _dio;

  Future<Map<String, dynamic>> get(String path, {Map<String, dynamic>? query}) =>
      _send(() => _dio.get(path, queryParameters: _clean(query)));

  Future<Map<String, dynamic>> post(String path, {Object? body}) => _send(() => _dio.post(path, data: body));

  Future<Map<String, dynamic>> patch(String path, {Object? body}) => _send(() => _dio.patch(path, data: body));

  Future<Map<String, dynamic>> _send(Future<Response<dynamic>> Function() call) async {
    try {
      final res = await call();
      final data = res.data;
      if (data is Map<String, dynamic>) {
        if (data['success'] == false) {
          throw ApiException((data['message'] ?? 'Request failed').toString(), statusCode: res.statusCode);
        }
        return data;
      }
      return {'data': data};
    } catch (e) {
      throw ApiException.from(e);
    }
  }

  static Map<String, dynamic>? _clean(Map<String, dynamic>? q) {
    if (q == null) return null;
    return {
      for (final e in q.entries)
        if (e.value != null && e.value.toString().isNotEmpty) e.key: e.value,
    };
  }
}

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: Env.apiBaseUrl,
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 30),
      headers: {'Accept': 'application/json'},
      contentType: Headers.jsonContentType,
    ),
  );
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        final token = ref.read(tokenStoreProvider).cached;
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
    ),
  );
  return dio;
});

final apiClientProvider = Provider<ApiClient>((ref) => ApiClient(ref.watch(dioProvider)));
