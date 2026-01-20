import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/auth_tokens.dart';

class TokenStorage {
  static const String _tokenKey = 'auth_tokens';

  Future<AuthTokens?> readTokens() async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(_tokenKey);
    if (raw == null || raw.isEmpty) {
      return null;
    }
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, Object?>) {
      return null;
    }
    return AuthTokens.fromJson(decoded);
  }

  Future<void> saveTokens(AuthTokens tokens) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_tokenKey, jsonEncode(tokens.toJson()));
  }

  Future<void> clearTokens() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_tokenKey);
  }
}
