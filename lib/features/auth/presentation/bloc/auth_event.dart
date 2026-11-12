import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class AuthCheckRequested extends AuthEvent {
  const AuthCheckRequested();
}

class AuthLoginRequested extends AuthEvent {
  final String username;
  final String password;

  const AuthLoginRequested({required this.username, required this.password});

  @override
  List<Object?> get props => [username, password];
}

class AuthProfileRefreshRequested extends AuthEvent {
  const AuthProfileRefreshRequested();
}

class AuthLogoutRequested extends AuthEvent {
  final String? message;
  const AuthLogoutRequested({this.message});

  @override
  List<Object?> get props => [message];
}

class AuthSessionExpiredEvent extends AuthEvent {
  const AuthSessionExpiredEvent();
}

/// Scenario 4: Injects expired access token and triggers GET /me,
/// proving AuthInterceptor refreshes the token and retries successfully.
class AuthTestTokenExpiryRequested extends AuthEvent {
  const AuthTestTokenExpiryRequested();
}

/// Scenario 5: Injects invalid refresh token and expired access token,
/// proving refresh failure triggers session clear and redirect to login.
class AuthTestRefreshFailureRequested extends AuthEvent {
  const AuthTestRefreshFailureRequested();
}
