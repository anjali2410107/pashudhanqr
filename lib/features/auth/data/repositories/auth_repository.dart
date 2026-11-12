import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/storage/token_storage.dart';
import '../models/auth_tokens_model.dart';
import '../models/user_model.dart';

class AuthRepository {
  final DioClient dioClient;
  final TokenStorage tokenStorage;

  AuthRepository({
    required this.dioClient,
    required this.tokenStorage,
  });

  Future<UserModel> login({
    required String username,
    required String password,
  }) async {
    try {
      final response = await dioClient.dio.post(
        ApiConstants.loginEndpoint,
        data: {
          'username': username,
          'password': password,
        },
        options: Options(
          extra: {'noAuth': true},
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        final authData = AuthTokensModel.fromJson(response.data as Map<String, dynamic>);
        await tokenStorage.saveTokens(
          accessToken: authData.accessToken,
          refreshToken: authData.refreshToken,
        );

        if (authData.user != null) {
          return authData.user!;
        }
        return await getCurrentUser();
      } else {
        throw const AuthException('Invalid server response during login');
      }
    } on DioException catch (e) {
      if (e.response != null) {
        final statusCode = e.response!.statusCode;
        final data = e.response!.data;
        String errorMessage = 'Login failed';
        if (data is Map && data.containsKey('message')) {
          errorMessage = data['message'].toString();
        } else if (data is Map && data.containsKey('title')) {
          errorMessage = data['title'].toString();
        } else if (statusCode == 400 || statusCode == 401) {
          errorMessage = 'Invalid username or password';
        }
        throw AuthException(errorMessage, statusCode: statusCode, details: data);
      }
      throw NetworkException(
        e.type == DioExceptionType.connectionTimeout ||
                e.type == DioExceptionType.receiveTimeout
            ? 'Connection timed out. Check your internet connection.'
            : 'Network error: ${e.message}',
      );
    } catch (e) {
      if (e is AppException) rethrow;
      throw AppException('Unexpected error during login: $e');
    }
  }

  Future<UserModel> getCurrentUser() async {
    try {
      final response = await dioClient.dio.get(ApiConstants.meEndpoint);
      if (response.statusCode == 200 && response.data != null) {
        return UserModel.fromJson(response.data as Map<String, dynamic>);
      }
      throw const AuthException('Failed to retrieve user profile');
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw const AuthException('Session expired. Please log in again.', statusCode: 401);
      }
      throw NetworkException(
        e.response?.data?['message'] ?? e.message ?? 'Failed to load profile',
        statusCode: e.response?.statusCode,
      );
    } catch (e) {
      if (e is AppException) rethrow;
      throw AppException('Unexpected error retrieving profile: $e');
    }
  }

  Future<String> getExpiredToken() async {
    try {
      final response = await dioClient.dio.get(
        ApiConstants.expiredTokenEndpoint,
        options: Options(extra: {'noAuth': true}),
      );
      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        return (data['accessToken'] ?? data['access_token']) as String;
      }
      throw const AppException('Failed to fetch expired test token');
    } on DioException catch (e) {
      throw NetworkException('Error fetching expired token: ${e.message}');
    }
  }

  Future<void> injectExpiredToken() async {
    final expiredToken = await getExpiredToken();
    await tokenStorage.saveAccessToken(expiredToken);
  }

  Future<void> injectInvalidRefreshToken() async {
    await tokenStorage.saveRefreshToken('invalid_refresh_token_12345');
  }

  Future<void> logout() async {
    await tokenStorage.clearTokens();
  }

  Future<bool> isAuthenticated() async {
    return tokenStorage.hasTokens();
  }
}
