import 'dart:io';
import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/network/dio_client.dart';
import '../models/echo_response_model.dart';
import '../models/upload_item.dart';

typedef ProgressCallback = void Function(double progress);

class UploadRepository {
  final DioClient dioClient;

  UploadRepository({required this.dioClient});

  Future<EchoResponseModel> uploadFile({
    required UploadItem item,
    ProgressCallback? onProgress,
    int? simulateDelay,
    int? simulateError,
  }) async {
    final file = File(item.filePath);
    if (!await file.exists()) {
      throw FileProcessingException('File not found at path: ${item.filePath}');
    }

    try {
      // Parse MIME type safely
      MediaType? mediaType;
      try {
        final parts = item.mimeType.split('/');
        if (parts.length == 2) {
          mediaType = MediaType(parts[0], parts[1]);
        }
      } catch (_) {
        mediaType = MediaType('application', 'octet-stream');
      }

      // Memory-efficient streaming: MultipartFile.fromFile streams directly
      // from disk, preventing Out-Of-Memory issues on large videos.
      final multipartFile = await MultipartFile.fromFile(
        item.filePath,
        filename: item.fileName,
        contentType: mediaType,
      );

      final formData = FormData.fromMap({
        'file': multipartFile,
        'mediaType': item.mimeType,
        'description': item.description.isNotEmpty
            ? item.description
            : 'Uploaded via Flutter Mobile Assessment',
        'uploadedAt': DateTime.now().toIso8601String(),
        'fileSize': item.fileSize.toString(),
      });

      // Construct endpoint with optional testing simulation parameters (?delay=X, ?error=Y)
      final queryParams = <String, dynamic>{};
      if (simulateDelay != null && simulateDelay > 0) {
        queryParams['delay'] = simulateDelay;
      }
      if (simulateError != null && simulateError > 0) {
        queryParams['error'] = simulateError;
      }

      final response = await dioClient.dio.post(
        ApiConstants.echoEndpoint,
        data: formData,
        queryParameters: queryParams,
        onSendProgress: (int sent, int total) {
          if (total > 0 && onProgress != null) {
            final fraction = sent / total;
            onProgress(fraction.clamp(0.0, 1.0));
          }
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        return EchoResponseModel.fromJson(response.data as Map<String, dynamic>);
      } else {
        throw NetworkException(
          'Upload completed with unexpected status code: ${response.statusCode}',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      if (e.response != null) {
        final code = e.response!.statusCode;
        throw NetworkException(
          'Server returned HTTP $code: ${e.response?.statusMessage ?? "Upload failed"}',
          statusCode: code,
          details: e.response?.data,
        );
      }
      if (e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.connectionTimeout) {
        throw const NetworkException('Upload timed out. The network might be slow or unstable.');
      }
      throw NetworkException('Network error during upload: ${e.message}');
    } catch (e) {
      if (e is AppException) rethrow;
      throw AppException('Unexpected error during upload: $e');
    }
  }
}
