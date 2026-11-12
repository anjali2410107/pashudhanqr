import 'package:equatable/equatable.dart';

class UserClaim extends Equatable {
  final String type;
  final String value;

  const UserClaim({required this.type, required this.value});

  factory UserClaim.fromJson(Map<String, dynamic> json) {
    return UserClaim(
      type: json['type'] as String? ?? '',
      value: json['value'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'value': value,
    };
  }

  @override
  List<Object?> get props => [type, value];
}

class UserModel extends Equatable {
  final String username;
  final String? name;
  final String? role;
  final String? email;
  final List<UserClaim> claims;

  const UserModel({
    required this.username,
    this.name,
    this.role,
    this.email,
    this.claims = const [],
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    var rawClaims = json['claims'];
    List<UserClaim> claimsList = [];
    if (rawClaims is List) {
      claimsList = rawClaims
          .whereType<Map<String, dynamic>>()
          .map((c) => UserClaim.fromJson(c))
          .toList();
    }

    return UserModel(
      username: json['username'] as String? ?? '',
      name: json['name'] as String?,
      role: json['role'] as String?,
      email: json['email'] as String?,
      claims: claimsList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'name': name,
      'role': role,
      'email': email,
      'claims': claims.map((c) => c.toJson()).toList(),
    };
  }

  @override
  List<Object?> get props => [username, name, role, email, claims];
}
