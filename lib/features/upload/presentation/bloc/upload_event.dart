import 'package:equatable/equatable.dart';
import '../../data/models/echo_response_model.dart';
import '../../data/models/upload_item.dart';

abstract class UploadEvent extends Equatable {
  const UploadEvent();

  @override
  List<Object?> get props => [];
}

class UploadQueueAdded extends UploadEvent {
  final List<UploadItem> items;
  const UploadQueueAdded(this.items);

  @override
  List<Object?> get props => [items];
}

class UploadItemRemoved extends UploadEvent {
  final String id;
  const UploadItemRemoved(this.id);

  @override
  List<Object?> get props => [id];
}

class UploadItemStarted extends UploadEvent {
  final String id;
  final int? simulateDelay;
  final int? simulateError;

  const UploadItemStarted(this.id, {this.simulateDelay, this.simulateError});

  @override
  List<Object?> get props => [id, simulateDelay, simulateError];
}

class UploadAllStarted extends UploadEvent {
  final int? simulateDelay;
  final int? simulateError;

  const UploadAllStarted({this.simulateDelay, this.simulateError});

  @override
  List<Object?> get props => [simulateDelay, simulateError];
}

class UploadItemProgressUpdated extends UploadEvent {
  final String id;
  final double progress;

  const UploadItemProgressUpdated({required this.id, required this.progress});

  @override
  List<Object?> get props => [id, progress];
}

class UploadItemSucceeded extends UploadEvent {
  final String id;
  final EchoResponseModel echo;

  const UploadItemSucceeded({required this.id, required this.echo});

  @override
  List<Object?> get props => [id, echo];
}

class UploadItemFailed extends UploadEvent {
  final String id;
  final String error;

  const UploadItemFailed({required this.id, required this.error});

  @override
  List<Object?> get props => [id, error];
}

class UploadClearCompleted extends UploadEvent {
  const UploadClearCompleted();
}

