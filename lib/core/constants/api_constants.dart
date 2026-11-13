class ApiConstants {
  ApiConstants._();

  static const String baseUrl = 'https://api.testingapis.com';

  static const String loginEndpoint = '/api/auth/jwt/login';
  static const String refreshEndpoint = '/api/auth/jwt/refresh';
  static const String meEndpoint = '/api/auth/jwt/me';
  static const String expiredTokenEndpoint = '/api/auth/jwt/expired';

  static const String echoEndpoint = '/api/echo';
  static const String largeBodyEndpoint = '/api/bodies/large';

  static const Duration connectTimeout = Duration(seconds: 20);
  static const Duration receiveTimeout = Duration(seconds: 25);
  static const Duration sendTimeout = Duration(seconds: 60);

  static const String defaultUsername = 'user';
  static const String defaultPassword = 'user123';
}
