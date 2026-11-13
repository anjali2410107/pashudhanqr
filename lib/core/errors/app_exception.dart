class AppException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic details;

  const AppException(this.message, {this.statusCode, this.details});

  @override
  String toString() => message;
}

class NetworkException extends AppException {
  const NetworkException(super.message, {super.statusCode, super.details});
}

class AuthException extends AppException {
  const AuthException(super.message, {super.statusCode, super.details});
}

class PermissionException extends AppException {
  const PermissionException(super.message, {super.statusCode, super.details});
}

class FileProcessingException extends AppException {
  const FileProcessingException(super.message, {super.statusCode, super.details});
}

