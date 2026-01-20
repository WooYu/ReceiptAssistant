import 'package:http/http.dart' as http;

import '../models/auth_tokens.dart';
import 'auth_service.dart';

typedef HeaderMap = Map<String, String>;

typedef OnRefreshExpired = Future<void> Function();

class ApiClient {
  ApiClient({
    required AuthService authService,
    http.Client? client,
    OnRefreshExpired? onRefreshExpired,
  })  : _authService = authService,
        _client = client ?? http.Client(),
        _onRefreshExpired = onRefreshExpired;

  final AuthService _authService;
  final http.Client _client;
  final OnRefreshExpired? _onRefreshExpired;

  Future<http.Response> get(Uri uri, {HeaderMap? headers}) {
    return _sendWithAuth((token) {
      return _client.get(uri, headers: _mergeHeaders(token, headers));
    });
  }

  Future<http.Response> post(
    Uri uri, {
    HeaderMap? headers,
    Object? body,
  }) {
    return _sendWithAuth((token) {
      return _client.post(
        uri,
        headers: _mergeHeaders(token, headers),
        body: body,
      );
    });
  }

  Future<http.Response> put(
    Uri uri, {
    HeaderMap? headers,
    Object? body,
  }) {
    return _sendWithAuth((token) {
      return _client.put(
        uri,
        headers: _mergeHeaders(token, headers),
        body: body,
      );
    });
  }

  Future<http.Response> delete(Uri uri, {HeaderMap? headers}) {
    return _sendWithAuth((token) {
      return _client.delete(uri, headers: _mergeHeaders(token, headers));
    });
  }

  HeaderMap _mergeHeaders(String? token, HeaderMap? headers) {
    final merged = <String, String>{};
    if (headers != null) {
      merged.addAll(headers);
    }
    if (token != null && token.isNotEmpty) {
      merged['Authorization'] = 'Bearer $token';
    }
    return merged;
  }

  Future<http.Response> _sendWithAuth(
    Future<http.Response> Function(String? token) request,
  ) async {
    final tokens = _authService.tokensNotifier.value;
    var response = await request(tokens?.accessToken);
    if (response.statusCode == 401) {
      final refreshed = await _refreshTokens();
      if (refreshed != null) {
        response = await request(refreshed.accessToken);
      }
    }
    if (response.statusCode == 403) {
      await _authService.clearTokens();
      if (_onRefreshExpired != null) {
        await _onRefreshExpired!();
      }
    }
    return response;
  }

  Future<AuthTokens?> _refreshTokens() async {
    try {
      final refreshed = await _authService.refreshTokens();
      if (refreshed != null) {
        await _authService.saveTokens(refreshed);
      }
      return refreshed;
    } on AuthException catch (error) {
      if (error.failure == AuthFailure.refreshExpired) {
        await _authService.clearTokens();
        if (_onRefreshExpired != null) {
          await _onRefreshExpired!();
        }
        return null;
      }
      rethrow;
    }
  }
}
