import 'package:dio/dio.dart';
import '../constants/api_constants.dart';
import '../storage/token_storage.dart';
import 'auth_interceptor.dart';

class DioClient {
  final Dio _dio;
  final TokenStorage tokenStorage;
  final OnSessionExpired? onSessionExpired;

  DioClient({
    required this.tokenStorage,
    this.onSessionExpired,
  }) : _dio = Dio(
          BaseOptions(
            baseUrl: ApiConstants.baseUrl,
            connectTimeout: ApiConstants.connectTimeout,
            receiveTimeout: ApiConstants.receiveTimeout,
            sendTimeout: ApiConstants.sendTimeout,
            headers: {
              'Accept': 'application/json',
            },
            validateStatus: (status) => status != null && status >= 200 && status < 300,
          ),
        ) {
    _dio.interceptors.add(
      AuthInterceptor(
        tokenStorage: tokenStorage,
        dio: _dio,
        onSessionExpired: onSessionExpired,
      ),
    );

    // Optional logging interceptor for debug visibility
    _dio.interceptors.add(
      LogInterceptor(
        requestHeader: true,
        requestBody: true,
        responseHeader: false,
        responseBody: true,
        error: true,
      ),
    );
  }

  Dio get dio => _dio;
}
