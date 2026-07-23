import 'package:dio/dio.dart';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/config/app_config.dart';
import '../../../core/storage/secure_storage_service.dart';

class AuthSession {
  const AuthSession(this.accessToken, this.refreshToken, this.expiresAt);
  final String accessToken;
  final String refreshToken;
  final DateTime expiresAt;
}

class AuthService {
  AuthService(String apiBaseUrl, this._storage)
      : _client = Dio(BaseOptions(baseUrl: apiBaseUrl));
  static const _access = 'nutrilens.auth.access';
  static const _refresh = 'nutrilens.auth.refresh';
  static const _expiry = 'nutrilens.auth.expiry';
  final SecureStorageService _storage;
  final Dio _client;
  Future<String?> accessToken() => _storage.read(_access);
  Future<String?> userId() async {
    final token = await accessToken();
    if (token == null) return null;
    try {
      final payload = token.split('.')[1];
      final json = jsonDecode(
              utf8.decode(base64Url.decode(base64Url.normalize(payload))))
          as Map<String, dynamic>;
      return json['sub'] as String?;
    } catch (_) {
      return null;
    }
  }

  Future<bool> hasSession() async => (await _storage.read(_refresh)) != null;

  Future<AuthSession> signIn(String email, String password,
      {bool register = false}) async {
    final response = await _client.post<dynamic>(
        '/api/auth/${register ? 'register' : 'login'}',
        data: {'email': email.trim(), 'password': password});
    return _store(Map<String, dynamic>.from(response.data as Map));
  }

  Future<String?> refresh() async {
    final refreshToken = await _storage.read(_refresh);
    if (refreshToken == null) return null;
    try {
      final response = await _client.post<dynamic>('/api/auth/refresh',
          data: {'refreshToken': refreshToken});
      return (await _store(Map<String, dynamic>.from(response.data as Map)))
          .accessToken;
    } on DioException {
      await clear();
      return null;
    }
  }

  Future<void> signOut() async {
    final token = await _storage.read(_refresh);
    if (token != null) {
      try {
        await _client
            .post<dynamic>('/api/auth/logout', data: {'refreshToken': token});
      } on DioException {
        // Local sign-out must still complete while offline.
      }
    }
    await clear();
  }

  Future<void> clear() async {
    await Future.wait([
      _storage.delete(_access),
      _storage.delete(_refresh),
      _storage.delete(_expiry)
    ]);
  }

  Future<AuthSession> _store(Map<String, dynamic> json) async {
    final session = AuthSession(
        json['accessToken'] as String,
        json['refreshToken'] as String,
        DateTime.parse(json['accessTokenExpiresAtUtc'] as String).toUtc());
    await Future.wait([
      _storage.write(_access, session.accessToken),
      _storage.write(_refresh, session.refreshToken),
      _storage.write(_expiry, session.expiresAt.toIso8601String())
    ]);
    return session;
  }
}

final authServiceProvider = Provider<AuthService>((ref) => AuthService(
    ref.watch(apiBaseUrlProvider), ref.watch(secureStorageProvider)));
