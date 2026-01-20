import 'package:flutter/foundation.dart';

import '../models/auth_tokens.dart';
import '../services/auth_service.dart';

enum AuthStatus {
  checking,
  authenticated,
  unauthenticated,
}

class AuthController extends ChangeNotifier {
  AuthController({required AuthService authService})
      : _authService = authService {
    _authService.tokensNotifier.addListener(_handleTokenUpdate);
  }

  final AuthService _authService;

  AuthStatus _status = AuthStatus.checking;
  String? _lastError;

  AuthStatus get status => _status;
  String? get lastError => _lastError;
  AuthTokens? get tokens => _authService.tokensNotifier.value;

  Future<void> initialize() async {
    await _authService.loadTokens();
    _handleTokenUpdate();
  }

  Future<void> login({
    required String username,
    required String password,
  }) async {
    _lastError = null;
    notifyListeners();
    try {
      final tokens = await _authService.login(
        username: username,
        password: password,
      );
      await _authService.saveTokens(tokens);
    } on AuthException catch (error) {
      _lastError = error.message;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await _authService.clearTokens();
  }

  void _handleTokenUpdate() {
    final tokens = _authService.tokensNotifier.value;
    _status = tokens == null ? AuthStatus.unauthenticated : AuthStatus.authenticated;
    notifyListeners();
  }

  @override
  void dispose() {
    _authService.tokensNotifier.removeListener(_handleTokenUpdate);
    super.dispose();
  }
}
