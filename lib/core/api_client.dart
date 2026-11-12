import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'config.dart';

/// Holds the access token in memory (so requests never wait on disk) and
/// mirrors it to the platform keystore / keychain.
class TokenStore {
  TokenStore([FlutterSecureStorage? storage])
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
            );

  static const _key = 'access_token';
  final FlutterSecureStorage _storage;

  String? _cached;
  bool _loaded = false;

  Future<String?> read() async {
    if (_loaded) return _cached;
    try {
      _cached = await _storage.read(key: _key);
    } catch (_) {
      // A corrupted keystore must not brick the app: treat as signed out.
      _cached = null;
    }
    _loaded = true;
    return _cached;
  }

  Future<void> save(String token) async {
    _cached = token;
    _loaded = true;
    await _storage.write(key: _key, value: token);
  }

  Future<void> clear() async {
    _cached = null;
    _loaded = true;
    try {
      await _storage.delete(key: _key);
    } catch (_) {}
  }
}

/// Dio wrapper: base URL, timeouts, bearer token, 401 handling and a small
/// retry for idempotent GET requests on flaky mobile networks.
class ApiClient {
  ApiClient({TokenStore? tokens, Dio? dio})
      : tokens = tokens ?? TokenStore(),
        dio = dio ??
            Dio(BaseOptions(
              baseUrl: AppConfig.apiBaseUrl,
              connectTimeout: const Duration(seconds: 15),
              receiveTimeout: const Duration(seconds: 20),
              sendTimeout: const Duration(seconds: 20),
              headers: {'Accept': 'application/json'},
            )) {
    this.dio.interceptors.add(
          InterceptorsWrapper(
            onRequest: (options, handler) async {
              final token = await this.tokens.read();
              if (token != null && token.isNotEmpty) {
                options.headers['Authorization'] = 'Bearer $token';
              }
              handler.next(options);
            },
            onError: (error, handler) async {
              final status = error.response?.statusCode;
              final path = error.requestOptions.path;
              final isAuthCall = path.startsWith('/auth/login') ||
                  path.startsWith('/auth/register');

              // Expired / revoked token on a protected call.
              if (status == 401 && !isAuthCall) {
                final hadToken = (await this.tokens.read()) != null;
                if (hadToken) {
                  await this.tokens.clear();
                  onUnauthorized?.call();
                }
              }

              if (_shouldRetry(error)) {
                final attempt = (error.requestOptions.extra['attempt'] as int?) ?? 0;
                if (attempt < 2) {
                  error.requestOptions.extra['attempt'] = attempt + 1;
                  await Future<void>.delayed(
                    Duration(milliseconds: 400 * (attempt + 1)),
                  );
                  try {
                    final response = await this.dio.fetch<dynamic>(error.requestOptions);
                    return handler.resolve(response);
                  } on DioException catch (retryError) {
                    return handler.next(retryError);
                  }
                }
              }
              handler.next(error);
            },
          ),
        );
  }

  final Dio dio;
  final TokenStore tokens;

  /// Called after a protected request fails with 401 and the stored token
  /// has been cleared. The auth controller listens to this.
  VoidCallback? onUnauthorized;

  static bool _shouldRetry(DioException e) {
    if (e.requestOptions.method.toUpperCase() != 'GET') return false;
    return e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.connectionError ||
        (e.response?.statusCode ?? 0) >= 502 && (e.response?.statusCode ?? 0) <= 504;
  }

  Future<String?> readToken() => tokens.read();
  Future<void> saveToken(String token) => tokens.save(token);
  Future<void> clearToken() => tokens.clear();
}

final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());
