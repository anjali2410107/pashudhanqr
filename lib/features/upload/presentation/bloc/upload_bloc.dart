import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/upload_item.dart';
import '../../data/repositories/upload_repository.dart';
import 'upload_event.dart';
import 'upload_state.dart';

class UploadBloc extends Bloc<UploadEvent, UploadState> {
  final UploadRepository uploadRepository;

  UploadBloc({required this.uploadRepository})
      : super(const UploadState()) {
    on<UploadQueueAdded>(_onQueueAdded);
    on<UploadItemRemoved>(_onItemRemoved);
    on<UploadItemStarted>(_onItemStarted);
    on<UploadAllStarted>(_onAllStarted);
    on<UploadItemProgressUpdated>(_onProgressUpdated);
    on<UploadItemSucceeded>(_onItemSucceeded);
    on<UploadItemFailed>(_onItemFailed);
    on<UploadClearCompleted>(_onClearCompleted);
  }

  void _onQueueAdded(UploadQueueAdded event, Emitter<UploadState> emit) {
    final updated = List<UploadItem>.from(state.items)..addAll(event.items);
    emit(state.copyWith(
      items: updated,
      statusMessage: 'Added ${event.items.length} item(s) to queue',
    ));
  }

  void _onItemRemoved(UploadItemRemoved event, Emitter<UploadState> emit) {
    final updated = state.items.where((i) => i.id != event.id).toList();
    emit(state.copyWith(
      items: updated,
      statusMessage: 'Item removed',
    ));
  }

  Future<void> _onItemStarted(UploadItemStarted event, Emitter<UploadState> emit) async {
    final index = state.items.indexWhere((i) => i.id == event.id);
    if (index == -1) return;

    final targetItem = state.items[index];
    final updatedItems = List<UploadItem>.from(state.items);
    updatedItems[index] = targetItem.copyWith(
      status: UploadStatus.uploading,
      progress: 0.0,
      errorMessage: null,
    );

    emit(state.copyWith(
      items: updatedItems,
      isUploading: true,
      activeUploadId: targetItem.id,
    ));

    try {
      final echo = await uploadRepository.uploadFile(
        item: targetItem,
        simulateDelay: event.simulateDelay,
        simulateError: event.simulateError,
        onProgress: (progress) {
          add(UploadItemProgressUpdated(id: targetItem.id, progress: progress));
        },
      );
      add(UploadItemSucceeded(id: targetItem.id, echo: echo));
    } catch (e) {
      add(UploadItemFailed(id: targetItem.id, error: e.toString()));
    }
  }

  Future<void> _onAllStarted(UploadAllStarted event, Emitter<UploadState> emit) async {
    final pendingItems = state.items
        .where((i) => i.status == UploadStatus.idle || i.status == UploadStatus.failed)
        .toList();

    for (final item in pendingItems) {
      add(UploadItemStarted(
        item.id,
        simulateDelay: event.simulateDelay,
        simulateError: event.simulateError,
      ));
      await stream.firstWhere((s) => s.activeUploadId != item.id);
    }
  }

  void _onProgressUpdated(UploadItemProgressUpdated event, Emitter<UploadState> emit) {
    final index = state.items.indexWhere((i) => i.id == event.id);
    if (index == -1) return;

    final updatedItems = List<UploadItem>.from(state.items);
    updatedItems[index] = updatedItems[index].copyWith(progress: event.progress);

    emit(state.copyWith(items: updatedItems));
  }

  void _onItemSucceeded(UploadItemSucceeded event, Emitter<UploadState> emit) {
    final index = state.items.indexWhere((i) => i.id == event.id);
    if (index == -1) return;

    final updatedItems = List<UploadItem>.from(state.items);
    updatedItems[index] = updatedItems[index].copyWith(
      status: UploadStatus.success,
      progress: 1.0,
      echoResult: event.echo,
      errorMessage: null,
    );

    emit(state.copyWith(
      items: updatedItems,
      isUploading: false,
      clearActiveUploadId: true,
      statusMessage: 'Upload completed: ${updatedItems[index].fileName}',
    ));
  }

  void _onItemFailed(UploadItemFailed event, Emitter<UploadState> emit) {
    final index = state.items.indexWhere((i) => i.id == event.id);
    if (index == -1) return;

    final updatedItems = List<UploadItem>.from(state.items);
    updatedItems[index] = updatedItems[index].copyWith(
      status: UploadStatus.failed,
      progress: 0.0,
      errorMessage: event.error,
    );

    emit(state.copyWith(
      items: updatedItems,
      isUploading: false,
      clearActiveUploadId: true,
      statusMessage: 'Upload failed: ${event.error}',
    ));
  }

  void _onClearCompleted(UploadClearCompleted event, Emitter<UploadState> emit) {
    final updated = state.items.where((i) => i.status != UploadStatus.success).toList();
    emit(state.copyWith(items: updated, statusMessage: 'Cleared completed uploads'));
  }
}
