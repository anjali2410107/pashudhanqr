import 'package:flutter_test/flutter_test.dart';
import 'package:pashudhanqr/core/utils/file_utils.dart';
import 'package:pashudhanqr/features/auth/data/models/auth_tokens_model.dart';
import 'package:pashudhanqr/features/auth/data/models/user_model.dart';
import 'package:pashudhanqr/features/upload/data/models/echo_response_model.dart';
import 'package:pashudhanqr/features/upload/data/models/upload_item.dart';

void main() {
  group('UserModel and Claims Tests', () {
    test('Correctly parses user model with claims from JSON', () {
      final json = {
        'username': 'user',
        'name': 'Uma User',
        'role': 'user',
        'email': 'user@example.com',
        'claims': [
          {'type': 'role', 'value': 'user'},
          {'type': 'jti', 'value': '12345'},
        ]
      };

      final user = UserModel.fromJson(json);

      expect(user.username, equals('user'));
      expect(user.name, equals('Uma User'));
      expect(user.role, equals('user'));
      expect(user.email, equals('user@example.com'));
      expect(user.claims.length, equals(2));
      expect(user.claims.first.type, equals('role'));
      expect(user.claims.first.value, equals('user'));
    });
  });

  group('AuthTokensModel Tests', () {
    test('Parses access and refresh tokens from JWT login response', () {
      final json = {
        'accessToken': 'jwt_access_123',
        'refreshToken': 'jrt_refresh_456',
        'tokenType': 'Bearer',
        'expiresIn': 900,
        'user': {
          'username': 'user',
          'role': 'user',
          'name': 'Uma User',
        }
      };

      final authModel = AuthTokensModel.fromJson(json);

      expect(authModel.accessToken, equals('jwt_access_123'));
      expect(authModel.refreshToken, equals('jrt_refresh_456'));
      expect(authModel.tokenType, equals('Bearer'));
      expect(authModel.expiresIn, equals(900));
      expect(authModel.user?.name, equals('Uma User'));
    });
  });

  group('EchoResponseModel Tests', () {
    test('Parses multipart echo endpoint response properly', () {
      final json = {
        'form': {
          'mediaType': 'image/jpeg',
          'description': 'Test upload description'
        },
        'files': [
          {
            'field': 'file',
            'fileName': 'capture_01.jpg',
            'contentType': 'image/jpeg',
            'size': 2048576,
          }
        ],
        'timestamp': '2026-11-12T14:00:00Z',
      };

      final echo = EchoResponseModel.fromJson(json);

      expect(echo.form['mediaType'], equals('image/jpeg'));
      expect(echo.form['description'], equals('Test upload description'));
      expect(echo.files.length, equals(1));
      expect(echo.primaryFile?.fileName, equals('capture_01.jpg'));
      expect(echo.primaryFile?.contentType, equals('image/jpeg'));
      expect(echo.primaryFile?.size, equals(2048576));
    });
  });

  group('FileUtils Utilities Tests', () {
    test('Formats file sizes properly to human-readable string', () {
      expect(FileUtils.formatFileSize(0), equals('0 B'));
      expect(FileUtils.formatFileSize(500), equals('500 B'));
      expect(FileUtils.formatFileSize(1024), equals('1.0 KB'));
      expect(FileUtils.formatFileSize(1536), equals('1.5 KB'));
      expect(FileUtils.formatFileSize(1048576), equals('1.0 MB'));
      expect(FileUtils.formatFileSize(5242880), equals('5.0 MB'));
    });

    test('Identifies MIME types by file extension', () {
      expect(FileUtils.getMimeType('photo.jpg'), equals('image/jpeg'));
      expect(FileUtils.getMimeType('photo.png'), equals('image/png'));
      expect(FileUtils.getMimeType('video.mp4'), equals('video/mp4'));
      expect(FileUtils.getMimeType('video.mov'), equals('video/quicktime'));
      expect(FileUtils.isImage('photo.jpg'), isTrue);
      expect(FileUtils.isVideo('video.mp4'), isTrue);
      expect(FileUtils.isImage('video.mp4'), isFalse);
    });
  });

  group('UploadItem Tests', () {
    test('UploadItem copyWith and formatted size work as expected', () {
      final item = UploadItem(
        id: '1',
        filePath: '/tmp/test.jpg',
        fileName: 'test.jpg',
        fileSize: 2048,
        mimeType: 'image/jpeg',
        isVideo: false,
        createdAt: DateTime.now(),
      );

      expect(item.status, equals(UploadStatus.idle));
      expect(item.formattedSize, equals('2.0 KB'));

      final updated = item.copyWith(
        status: UploadStatus.uploading,
        progress: 0.5,
      );

      expect(updated.status, equals(UploadStatus.uploading));
      expect(updated.progress, equals(0.5));
    });
  });
}
