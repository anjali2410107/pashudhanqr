import 'package:equatable/equatable.dart';

class EchoFileMetadata extends Equatable {
  final String field;
  final String fileName;
  final String contentType;
  final int size;

  const EchoFileMetadata({
    required this.field,
    required this.fileName,
    required this.contentType,
    required this.size,
  });

  factory EchoFileMetadata.fromJson(Map<String, dynamic> json) {
    return EchoFileMetadata(
      field: json['field'] as String? ?? 'file',
      fileName: json['fileName'] as String? ?? '',
      contentType: json['contentType'] as String? ?? 'application/octet-stream',
      size: json['size'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'field': field,
      'fileName': fileName,
      'contentType': contentType,
      'size': size,
    };
  }

  @override
  List<Object?> get props => [field, fileName, contentType, size];
}

class EchoResponseModel extends Equatable {
  final Map<String, dynamic> form;
  final List<EchoFileMetadata> files;
  final String? timestamp;
  final String? rawUrl;

  const EchoResponseModel({
    required this.form,
    required this.files,
    this.timestamp,
    this.rawUrl,
  });

  factory EchoResponseModel.fromJson(Map<String, dynamic> json) {
    final rawForm = json['form'];
    final formMap = rawForm is Map ? Map<String, dynamic>.from(rawForm) : <String, dynamic>{};

    final rawFiles = json['files'];
    List<EchoFileMetadata> fileList = [];
    if (rawFiles is List) {
      fileList = rawFiles
          .whereType<Map<String, dynamic>>()
          .map((f) => EchoFileMetadata.fromJson(f))
          .toList();
    }

    return EchoResponseModel(
      form: formMap,
      files: fileList,
      timestamp: json['timestamp'] as String?,
      rawUrl: json['url'] as String?,
    );
  }

  EchoFileMetadata? get primaryFile => files.isNotEmpty ? files.first : null;

  @override
  List<Object?> get props => [form, files, timestamp, rawUrl];
}
