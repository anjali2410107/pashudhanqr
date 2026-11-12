import 'package:equatable/equatable.dart';
import '../../../../core/utils/file_utils.dart';
import 'echo_response_model.dart';

enum UploadStatus { idle, uploading, success, failed }

class UploadItem extends Equatable {
  final String id;
  final String filePath;
  final String fileName;
  final int fileSize;
  final String mimeType;
  final bool isVideo;
  final String description;
  final UploadStatus status;
  final double progress;
  final EchoResponseModel? echoResult;
  final String? errorMessage;
  final DateTime createdAt;

  const UploadItem({
    required this.id,
    required this.filePath,
    required this.fileName,
    required this.fileSize,
    required this.mimeType,
    required this.isVideo,
    this.description = '',
    this.status = UploadStatus.idle,
    this.progress = 0.0,
    this.echoResult,
    this.errorMessage,
    required this.createdAt,
  });

  String get formattedSize => FileUtils.formatFileSize(fileSize);

  UploadItem copyWith({
    String? id,
    String? filePath,
    String? fileName,
    int? fileSize,
    String? mimeType,
    bool? isVideo,
    String? description,
    UploadStatus? status,
    double? progress,
    EchoResponseModel? echoResult,
    String? errorMessage,
    DateTime? createdAt,
  }) {
    return UploadItem(
      id: id ?? this.id,
      filePath: filePath ?? this.filePath,
      fileName: fileName ?? this.fileName,
      fileSize: fileSize ?? this.fileSize,
      mimeType: mimeType ?? this.mimeType,
      isVideo: isVideo ?? this.isVideo,
      description: description ?? this.description,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      echoResult: echoResult ?? this.echoResult,
      errorMessage: errorMessage ?? this.errorMessage,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        filePath,
        fileName,
        fileSize,
        mimeType,
        isVideo,
        description,
        status,
        progress,
        echoResult,
        errorMessage,
        createdAt,
      ];
}
