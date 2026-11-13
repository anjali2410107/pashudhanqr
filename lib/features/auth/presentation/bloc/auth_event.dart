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

class AuthTestTokenExpiryRequested extends AuthEvent {
  const AuthTestTokenExpiryRequested();
}

class AuthTestRefreshFailureRequested extends AuthEvent {
  const AuthTestRefreshFailureRequested();
}

