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
  bool _simulateDelay = false;
  bool _simulateError = false;

  int? get _delayParam => _simulateDelay ? 3 : null;
  int? get _errorParam => _simulateError ? 503 : null;

  void _uploadItem(String id) {
    context.read<UploadBloc>().add(
          UploadItemStarted(
            id,
            simulateDelay: _delayParam,
            simulateError: _errorParam,
          ),
        );
  }

  void _uploadAll() {
    context.read<UploadBloc>().add(
          UploadAllStarted(
            simulateDelay: _delayParam,
            simulateError: _errorParam,
          ),
        );
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
              // Simulation Controls Panel
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                color: Colors.white,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.tune, size: 16, color: AppTheme.primaryColor),
                        SizedBox(width: 6),
                        Text(
                          'API Testing Options (testingapis.com):',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        FilterChip(
                          label: const Text('Simulate Delay (?delay=3)'),
                          selected: _simulateDelay,
                          onSelected: (val) {
                            setState(() => _simulateDelay = val);
                          },
                          selectedColor: Colors.blue.shade100,
                        ),
                        const SizedBox(width: 8),
                        FilterChip(
                          label: const Text('Simulate Error (?error=503)'),
                          selected: _simulateError,
                          onSelected: (val) {
                            setState(() => _simulateError = val);
                          },
                          selectedColor: Colors.red.shade100,
                        ),
                      ],
                    ),
                    if (state.pendingCount > 0) ...[
                      const SizedBox(height: 10),
                      ElevatedButton.icon(
                        onPressed: state.isUploading ? null : _uploadAll,
                        icon: const Icon(Icons.cloud_upload),
                        label: Text('Upload All Pending (${state.pendingCount})'),
                      ),
                    ],
                  ],
                ),
              ),
              const Divider(height: 1),

              // Queue Summary Bar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: Colors.grey.shade100,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total: ${items.length}  •  Pending: ${state.pendingCount}  •  Done: ${state.successCount}',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade800),
                    ),
                    if (state.isUploading)
                      Row(
                        children: const [
                          SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          SizedBox(width: 6),
                          Text('Uploading...', style: TextStyle(fontSize: 12)),
                        ],
                      ),
                  ],
                ),
              ),

              // Items List
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
            // Top Row: Thumbnail + Info + Status
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Thumbnail
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

                // File Details
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

                // Status Badge & Action
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

            // Progress Bar if Uploading
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

            // Error display + Retry Button
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

            // Success Display: Echo Response Metadata
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
                          'Echo Endpoint Receipt Verified',
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
                      _buildEchoRow('Echoed File:', item.echoResult!.primaryFile!.fileName),
                      _buildEchoRow('Content-Type:', item.echoResult!.primaryFile!.contentType),
                      _buildEchoRow(
                        'Echoed Size:',
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

            // Idle Action Button
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
