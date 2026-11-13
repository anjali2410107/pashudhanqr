import 'package:equatable/equatable.dart';
import '../../data/models/user_model.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {
  final String? message;
  const AuthLoading({this.message});

  @override
  List<Object?> get props => [message];
}

class AuthAuthenticated extends AuthState {
  final UserModel user;
  final String? infoMessage;

  const AuthAuthenticated({
    required this.user,
    this.infoMessage,
  });

  AuthAuthenticated copyWith({
    UserModel? user,
    String? infoMessage,
  }) {
    return AuthAuthenticated(
      user: user ?? this.user,
      infoMessage: infoMessage,
    );
  }

  @override
  List<Object?> get props => [user, infoMessage];
}

class AuthUnauthenticated extends AuthState {
  final String? message;
  const AuthUnauthenticated({this.message});

  @override
  List<Object?> get props => [message];
}

class AuthFailure extends AuthState {
  final String error;
  const AuthFailure(this.error);

  @override
  List<Object?> get props => [error];
}

