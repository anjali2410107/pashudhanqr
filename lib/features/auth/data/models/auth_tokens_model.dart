import 'package:equatable/equatable.dart';
import 'user_model.dart';

class AuthTokensModel extends Equatable {
  final String accessToken;
  final String refreshToken;
  final String tokenType;
  final int expiresIn;
  final UserModel? user;

  const AuthTokensModel({
    required this.accessToken,
    required this.refreshToken,
    this.tokenType = 'Bearer',
    this.expiresIn = 900,
    this.user,
  });

  factory AuthTokensModel.fromJson(Map<String, dynamic> json) {
    return AuthTokensModel(
      accessToken: (json['accessToken'] ?? json['access_token'] ?? '') as String,
      refreshToken: (json['refreshToken'] ?? json['refresh_token'] ?? '') as String,
      tokenType: (json['tokenType'] ?? json['token_type'] ?? 'Bearer') as String,
      expiresIn: (json['expiresIn'] ?? json['expires_in'] ?? 900) as int,
      user: json['user'] != null && json['user'] is Map<String, dynamic>
          ? UserModel.fromJson(json['user'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'accessToken': accessToken,
      'refreshToken': refreshToken,
      'tokenType': tokenType,
      'expiresIn': expiresIn,
      if (user != null) 'user': user!.toJson(),
    };
  }

  @override
  List<Object?> get props => [accessToken, refreshToken, tokenType, expiresIn, user];
}
