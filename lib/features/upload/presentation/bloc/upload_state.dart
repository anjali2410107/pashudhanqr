import 'package:equatable/equatable.dart';
import '../../data/models/upload_item.dart';

class UploadState extends Equatable {
  final List<UploadItem> items;
  final bool isUploading;
  final String? activeUploadId;
  final String? statusMessage;

  const UploadState({
    this.items = const [],
    this.isUploading = false,
    this.activeUploadId,
    this.statusMessage,
  });

  UploadItem? get activeItem {
    if (activeUploadId == null) return null;
    try {
      return items.firstWhere((i) => i.id == activeUploadId);
    } catch (_) {
      return null;
    }
  }

  int get pendingCount => items.where((i) => i.status == UploadStatus.idle).length;
  int get successCount => items.where((i) => i.status == UploadStatus.success).length;
  int get failedCount => items.where((i) => i.status == UploadStatus.failed).length;

  UploadState copyWith({
    List<UploadItem>? items,
    bool? isUploading,
    String? activeUploadId,
    String? statusMessage,
    bool clearActiveUploadId = false,
  }) {
    return UploadState(
      items: items ?? this.items,
      isUploading: isUploading ?? this.isUploading,
      activeUploadId: clearActiveUploadId ? null : (activeUploadId ?? this.activeUploadId),
      statusMessage: statusMessage,
    );
  }

  @override
  List<Object?> get props => [items, isUploading, activeUploadId, statusMessage];
}
