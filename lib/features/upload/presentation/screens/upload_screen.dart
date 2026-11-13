import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/file_utils.dart';
import '../../../camera/presentation/screens/media_preview_screen.dart';
import '../../data/models/upload_item.dart';
import '../bloc/upload_bloc.dart';
import '../bloc/upload_event.dart';
import '../bloc/upload_state.dart';

class UploadScreen extends StatefulWidget {
  const UploadScreen({super.key});

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  void _uploadItem(String id) {
    context.read<UploadBloc>().add(UploadItemStarted(id));
  }

  void _uploadAll() {
    context.read<UploadBloc>().add(const UploadAllStarted());
  }

  void _removeItem(String id) {
    context.read<UploadBloc>().add(UploadItemRemoved(id));
  }

  void _clearCompleted() {
    context.read<UploadBloc>().add(const UploadClearCompleted());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Media Upload Manager'),
        actions: [
          IconButton(
            icon: const Icon(Icons.cleaning_services_outlined),
            tooltip: 'Clear Completed',
            onPressed: _clearCompleted,
          ),
        ],
      ),
      body: BlocConsumer<UploadBloc, UploadState>(
        listener: (context, state) {},
        builder: (context, state) {
          final items = state.items;

          return Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                color: Colors.white,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Upload Queue (${items.length})',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Pending: ${state.pendingCount}  •  Completed: ${state.successCount}',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                    if (state.pendingCount > 0)
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                        ),
                        onPressed: state.isUploading ? null : _uploadAll,
                        icon: const Icon(Icons.cloud_upload, size: 16),
                        label: Text('Upload All (${state.pendingCount})'),
                      ),
                  ],
                ),
              ),
              const Divider(height: 1),

              Expanded(
                child: items.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.cloud_done_outlined, size: 56, color: Colors.grey.shade400),
                            const SizedBox(height: 14),
                            Text(
                              'Upload queue is empty',
                              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Capture media with Camera or select from Gallery',
                              style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: items.length,
                        itemBuilder: (context, index) {
                          final item = items[index];
                          return _buildUploadCard(item, state.isUploading);
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildUploadCard(UploadItem item, bool isAnyUploading) {
    final isUploadingThis = item.status == UploadStatus.uploading;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => MediaPreviewScreen(
                          filePath: item.filePath,
                          isVideo: item.isVideo,
                        ),
                      ),
                    );
                  },
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: 56,
                      height: 56,
                      color: Colors.grey.shade200,
                      child: item.isVideo
                          ? const Center(child: Icon(Icons.videocam, color: AppTheme.primaryColor))
                          : Image.file(
                              File(item.filePath),
                              fit: BoxFit.cover,
                              errorBuilder: (ctx, err, stack) => const Icon(Icons.broken_image),
                            ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.fileName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: Text(
                              item.mimeType,
                              style: TextStyle(fontSize: 10, color: Colors.grey.shade700),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            item.formattedSize,
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                      if (item.description.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          item.description,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Colors.grey.shade600),
                        ),
                      ],
                    ],
                  ),
                ),

                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _buildStatusBadge(item.status),
                    const SizedBox(height: 6),
                    if (item.status != UploadStatus.uploading)
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        icon: const Icon(Icons.delete_outline, size: 20, color: Colors.grey),
                        tooltip: 'Remove',
                        onPressed: () => _removeItem(item.id),
                      ),
                  ],
                ),
              ],
            ),

            if (isUploadingThis) ...[
              const SizedBox(height: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Uploading multipart...', style: TextStyle(fontSize: 12)),
                      Text('${(item.progress * 100).toInt()}%',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  LinearProgressIndicator(
                    value: item.progress > 0 ? item.progress : null,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                  ),
                ],
              ),
            ],

            if (item.status == UploadStatus.failed) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, size: 18, color: Colors.red.shade800),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        item.errorMessage ?? 'Upload failed',
                        style: TextStyle(color: Colors.red.shade900, fontSize: 12),
                      ),
                    ),
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.red.shade900,
                        visualDensity: VisualDensity.compact,
                      ),
                      onPressed: () => _uploadItem(item.id),
                      icon: const Icon(Icons.refresh, size: 16),
                      label: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ],

            if (item.status == UploadStatus.success && item.echoResult != null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.check_circle, size: 16, color: Colors.green.shade700),
                        const SizedBox(width: 6),
                        Text(
                          'Upload Verified',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade900,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    if (item.echoResult!.primaryFile != null) ...[
                      _buildEchoRow('Uploaded File:', item.echoResult!.primaryFile!.fileName),
                      _buildEchoRow('Content-Type:', item.echoResult!.primaryFile!.contentType),
                      _buildEchoRow(
                        'File Size:',
                        '${FileUtils.formatFileSize(item.echoResult!.primaryFile!.size)} (${item.echoResult!.primaryFile!.size} bytes)',
                      ),
                    ],
                    if (item.echoResult!.form.isNotEmpty)
                      _buildEchoRow(
                        'Form Metadata:',
                        item.echoResult!.form.entries.map((e) => '${e.key}: ${e.value}').join(', '),
                      ),
                  ],
                ),
              ),
            ],

            if (item.status == UploadStatus.idle) ...[
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    minimumSize: const Size(120, 36),
                  ),
                  onPressed: isAnyUploading ? null : () => _uploadItem(item.id),
                  icon: const Icon(Icons.upload, size: 16),
                  label: const Text('Upload'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(UploadStatus status) {
    Color bg = Colors.grey.shade200;
    Color fg = Colors.grey.shade800;
    String text = 'Ready';

    switch (status) {
      case UploadStatus.idle:
        bg = Colors.grey.shade200;
        fg = Colors.grey.shade800;
        text = 'Ready';
        break;
      case UploadStatus.uploading:
        bg = Colors.blue.shade100;
        fg = Colors.blue.shade900;
        text = 'Uploading';
        break;
      case UploadStatus.success:
        bg = Colors.green.shade100;
        fg = Colors.green.shade900;
        text = 'Uploaded';
        break;
      case UploadStatus.failed:
        bg = Colors.red.shade100;
        fg = Colors.red.shade900;
        text = 'Failed';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildEchoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(top: 2.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label ',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.green.shade900),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 11, color: Colors.green.shade900),
            ),
          ),
        ],
      ),
    );
  }
}
