import 'dart:async';
import 'package:dio/dio.dart';
import '../constants/api_constants.dart';
import '../storage/token_storage.dart';

typedef OnSessionExpired = void Function();

class AuthInterceptor extends QueuedInterceptor {
  final TokenStorage tokenStorage;
  final Dio dio;
  final OnSessionExpired? onSessionExpired;

  bool _isRefreshing = false;
  Completer<String?>? _refreshCompleter;

  AuthInterceptor({
    required this.tokenStorage,
    required this.dio,
    this.onSessionExpired,
  });

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    // If request explicitly opts out of auth header, proceed as is
    if (options.extra['noAuth'] == true) {
      return handler.next(options);
    }

    final path = options.path;
    final isAuthEndpoint = path.contains(ApiConstants.loginEndpoint) ||
        path.contains(ApiConstants.refreshEndpoint);

    if (!isAuthEndpoint) {
      final token = await tokenStorage.getAccessToken();
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }

    return handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final response = err.response;
    final requestOptions = err.requestOptions;

    // Check if the error is 401 and hasn't been retried yet
    final isUnauthorized = response?.statusCode == 401;
    final alreadyRetried = requestOptions.extra['retried'] == true;
    final isRefreshRequest =
        requestOptions.path.contains(ApiConstants.refreshEndpoint);

    if (isUnauthorized && !alreadyRetried && !isRefreshRequest) {
      requestOptions.extra['retried'] = true;

      try {
        final newAccessToken = await _handleTokenRefresh();
        if (newAccessToken != null && newAccessToken.isNotEmpty) {
          // Update header with fresh access token
          requestOptions.headers['Authorization'] = 'Bearer $newAccessToken';

          // Clone and retry original request
          final retryResponse = await dio.fetch(requestOptions);
          return handler.resolve(retryResponse);
        } else {
          _triggerLogout();
          return handler.next(err);
        }
      } catch (e) {
        _triggerLogout();
        return handler.next(err);
      }
    }

    return handler.next(err);
  }

  Future<String?> _handleTokenRefresh() async {
    // If another request is currently refreshing the token, await that same refresh
    if (_isRefreshing && _refreshCompleter != null) {
      return _refreshCompleter!.future;
    }

    _isRefreshing = true;
    _refreshCompleter = Completer<String?>();

    try {
      final refreshToken = await tokenStorage.getRefreshToken();
      if (refreshToken == null || refreshToken.isEmpty) {
        _refreshCompleter?.complete(null);
        return null;
      }

      // Use a clean Dio instance to avoid interceptor recursion
      final refreshDio = Dio(
        BaseOptions(
          baseUrl: ApiConstants.baseUrl,
          connectTimeout: ApiConstants.connectTimeout,
          receiveTimeout: ApiConstants.receiveTimeout,
          headers: {'Content-Type': 'application/json'},
        ),
      );

      final response = await refreshDio.post(
        ApiConstants.refreshEndpoint,
        data: {'refreshToken': refreshToken},
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        final newAccessToken =
            (data['accessToken'] ?? data['access_token']) as String?;
        final newRefreshToken =
            (data['refreshToken'] ?? data['refresh_token']) as String?;

        if (newAccessToken != null && newAccessToken.isNotEmpty) {
          await tokenStorage.saveAccessToken(newAccessToken);
          if (newRefreshToken != null && newRefreshToken.isNotEmpty) {
            await tokenStorage.saveRefreshToken(newRefreshToken);
          }
          _refreshCompleter?.complete(newAccessToken);
          return newAccessToken;
        }
      }

      _refreshCompleter?.complete(null);
      return null;
    } catch (e) {
      _refreshCompleter?.complete(null);
      return null;
    } finally {
      _isRefreshing = false;
      _refreshCompleter = null;
    }
  }

  void _triggerLogout() {
    tokenStorage.clearTokens();
    if (onSessionExpired != null) {
      onSessionExpired!();
    }
  }
}
