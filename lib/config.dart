class ApiConfig {
  static const String ocrEndpoint =
      String.fromEnvironment('OCR_ENDPOINT', defaultValue: '');
  static const String ocrApiKey =
      String.fromEnvironment('OCR_API_KEY', defaultValue: '');
  static const String ocrModel =
      String.fromEnvironment('OCR_MODEL', defaultValue: 'receipt-v1');

  static const String loginEndpoint =
      String.fromEnvironment('LOGIN_ENDPOINT', defaultValue: '');
  static const String refreshEndpoint =
      String.fromEnvironment('REFRESH_ENDPOINT', defaultValue: '');
}
