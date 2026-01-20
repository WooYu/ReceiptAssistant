import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config.dart';
import '../models/auth_tokens.dart';
import 'token_storage.dart';

typedef JsonMap = Map<String, Object?>;

enum AuthFailure {
  invalidCredentials,
  refreshExpired,
  invalidResponse,
  network,
}

class AuthException implements Exception {
  const AuthException(this.failure, this.message);

  final AuthFailure failure;
  final String message;

  @override
  String toString() => 'AuthException($failure): $message';
}

class AuthService {
  AuthService({
    required TokenStorage tokenStorage,
    http.Client? client,
  })  : _tokenStorage = tokenStorage,
        _client = client ?? http.Client();

  final TokenStorage _tokenStorage;
  final http.Client _client;

  final ValueNotifier<AuthTokens?> tokensNotifier = ValueNotifier(null);

  Future<void> loadTokens() async {
    tokensNotifier.value = await _tokenStorage.readTokens();
  }

  Future<void> saveTokens(AuthTokens tokens) async {
    await _tokenStorage.saveTokens(tokens);
    tokensNotifier.value = tokens;
  }

  Future<void> clearTokens() async {
    await _tokenStorage.clearTokens();
    tokensNotifier.value = null;
  }

  Future<AuthTokens> login({
    required String username,
    required String password,
  }) async {
    if (ApiConfig.loginEndpoint.isEmpty) {
      throw const AuthException(
        AuthFailure.network,
        'Login endpoint is not configured.',
      );
    }
    final uri = Uri.parse(ApiConfig.loginEndpoint);
    final response = await _client.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'password': password}),
    );

    if (response.statusCode == 401 || response.statusCode == 403) {
      throw const AuthException(
        AuthFailure.invalidCredentials,
        'Invalid username or password.',
      );
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw AuthException(
        AuthFailure.network,
        'Login failed: ${response.statusCode}.',
      );
    }

    final data = _decodeJson(response.body);
    if (data == null) {
      throw const AuthException(
        AuthFailure.invalidResponse,
        'Login response was invalid.',
      );
    }
    return AuthTokens.fromJson(data);
  }

  Future<AuthTokens?> refreshTokens() async {
    final current = tokensNotifier.value;
    if (current == null) {
      return null;
    }
    if (ApiConfig.refreshEndpoint.isEmpty) {
      throw const AuthException(
        AuthFailure.network,
        'Refresh endpoint is not configured.',
      );
    }
    final uri = Uri.parse(ApiConfig.refreshEndpoint);
    final response = await _client.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'refresh_token': current.refreshToken}),
    );

    if (response.statusCode == 403) {
      throw const AuthException(
        AuthFailure.refreshExpired,
        'Refresh token expired.',
      );
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw AuthException(
        AuthFailure.network,
        'Refresh failed: ${response.statusCode}.',
      );
    }

    final data = _decodeJson(response.body);
    if (data == null) {
      throw const AuthException(
        AuthFailure.invalidResponse,
        'Refresh response was invalid.',
      );
    }
    return AuthTokens.fromJson(data);
  }

  JsonMap? _decodeJson(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, Object?>) {
        return decoded;
      }
    } catch (_) {}
    return null;
  }
}
