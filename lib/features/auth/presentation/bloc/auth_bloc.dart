import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/errors/app_exception.dart';
import '../../data/repositories/auth_repository.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository authRepository;

  AuthBloc({required this.authRepository})
      : super(AuthInitial()) {
    on<AuthCheckRequested>(_onAuthCheckRequested);
    on<AuthLoginRequested>(_onAuthLoginRequested);
    on<AuthProfileRefreshRequested>(_onAuthProfileRefreshRequested);
    on<AuthLogoutRequested>(_onAuthLogoutRequested);
    on<AuthSessionExpiredEvent>(_onAuthSessionExpired);
    on<AuthTestTokenExpiryRequested>(_onAuthTestTokenExpiryRequested);
    on<AuthTestRefreshFailureRequested>(_onAuthTestRefreshFailureRequested);
  }

  Future<void> _onAuthCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading(message: 'Checking session...'));
    try {
      final isAuth = await authRepository.isAuthenticated();
      if (!isAuth) {
        emit(const AuthUnauthenticated());
        return;
      }
      final user = await authRepository.getCurrentUser();
      emit(AuthAuthenticated(user: user));
    } catch (e) {
      emit(const AuthUnauthenticated());
    }
  }

  Future<void> _onAuthLoginRequested(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading(message: 'Authenticating...'));
    try {
      final user = await authRepository.login(
        username: event.username,
        password: event.password,
      );
      emit(AuthAuthenticated(user: user));
    } on AppException catch (e) {
      emit(AuthFailure(e.message));
      emit(const AuthUnauthenticated());
    } catch (e) {
      emit(AuthFailure('Unexpected login failure: $e'));
      emit(const AuthUnauthenticated());
    }
  }

  Future<void> _onAuthProfileRefreshRequested(
    AuthProfileRefreshRequested event,
    Emitter<AuthState> emit,
  ) async {
    if (state is AuthAuthenticated) {
      final currentUser = (state as AuthAuthenticated).user;
      emit(const AuthLoading(message: 'Refreshing profile...'));
      try {
        final user = await authRepository.getCurrentUser();
        emit(AuthAuthenticated(
          user: user,
          infoMessage: 'Profile refreshed successfully',
        ));
      } catch (e) {
        emit(AuthAuthenticated(
          user: currentUser,
          infoMessage: 'Could not refresh profile: $e',
        ));
      }
    }
  }

  Future<void> _onAuthLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    await authRepository.logout();
    emit(AuthUnauthenticated(message: event.message ?? 'Logged out'));
  }

  void _onAuthSessionExpired(
    AuthSessionExpiredEvent event,
    Emitter<AuthState> emit,
  ) {
    emit(const AuthUnauthenticated(
      message: 'Your session expired and refresh failed. Please log in again.',
    ));
  }

  Future<void> _onAuthTestTokenExpiryRequested(
    AuthTestTokenExpiryRequested event,
    Emitter<AuthState> emit,
  ) async {
    if (state is! AuthAuthenticated) return;
    final currentUser = (state as AuthAuthenticated).user;

    emit(const AuthLoading(message: 'Injecting expired token and testing auto-refresh...'));
    try {
      // Step 1: Inject expired token
      await authRepository.injectExpiredToken();

      // Step 2: Make protected request to /me
      // The Dio interceptor will catch 401, call /refresh, save new tokens, and retry /me!
      final refreshedUser = await authRepository.getCurrentUser();

      emit(AuthAuthenticated(
        user: refreshedUser,
        infoMessage: 'Success! Expired token received 401, refresh token rotated automatically, and GET /me succeeded.',
      ));
    } catch (e) {
      emit(AuthAuthenticated(
        user: currentUser,
        infoMessage: 'Auto-refresh test error: $e',
      ));
    }
  }

  Future<void> _onAuthTestRefreshFailureRequested(
    AuthTestRefreshFailureRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading(message: 'Simulating refresh failure...'));
    try {
      // Corrupt refresh token and inject expired token
      await authRepository.injectInvalidRefreshToken();
      await authRepository.injectExpiredToken();

      // Attempt protected call; should fail refresh and trigger logout
      await authRepository.getCurrentUser();
    } catch (e) {
      // The interceptor triggers onSessionExpired which emits AuthUnauthenticated
      await authRepository.logout();
      emit(const AuthUnauthenticated(
        message: 'Refresh failed as expected (invalid refresh token). Session cleared.',
      ));
    }
  }
}
