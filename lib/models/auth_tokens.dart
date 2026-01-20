class AuthTokens {
  const AuthTokens({
    required this.accessToken,
    required this.refreshToken,
  });

  final String accessToken;
  final String refreshToken;

  Map<String, Object?> toJson() => {
        'access_token': accessToken,
        'refresh_token': refreshToken,
      };

  factory AuthTokens.fromJson(Map<String, Object?> json) {
    final accessToken = json['access_token'] ?? json['accessToken'];
    final refreshToken = json['refresh_token'] ?? json['refreshToken'];
    if (accessToken is! String || refreshToken is! String) {
      throw const FormatException('Missing auth tokens in response');
    }
    return AuthTokens(accessToken: accessToken, refreshToken: refreshToken);
  }
}
