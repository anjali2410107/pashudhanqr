import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/file_utils.dart';
import '../../../camera/presentation/screens/media_preview_screen.dart';
import '../../../upload/data/models/upload_item.dart';
import '../../../upload/presentation/bloc/upload_bloc.dart';
import '../../../upload/presentation/bloc/upload_event.dart';

class SelectedMediaItem {
  final String path;
  final String name;
  final int size;
  final String mimeType;
  final bool isVideo;

  SelectedMediaItem({
    required this.path,
    required this.name,
    required this.size,
    required this.mimeType,
    required this.isVideo,
  });
}

class GalleryPickerScreen extends StatefulWidget {
  const GalleryPickerScreen({super.key});

  @override
  State<GalleryPickerScreen> createState() => _GalleryPickerScreenState();
}

class _GalleryPickerScreenState extends State<GalleryPickerScreen> {
  final ImagePicker _picker = ImagePicker();
  final List<SelectedMediaItem> _selectedItems = [];
  bool _isLoading = false;

  Future<void> _pickMultipleMedia() async {
    setState(() => _isLoading = true);
    try {
      // Modern Android Photo Picker integration (multi-media)
      final List<XFile> pickedFiles = await _picker.pickMultipleMedia();
      if (pickedFiles.isEmpty) {
        // User cancelled picker
        _showInfo('Selection cancelled');
        return;
      }
      await _processPickedFiles(pickedFiles);
    } catch (e) {
      _showError('Failed to pick media: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickSingleImage() async {
    setState(() => _isLoading = true);
    try {
      final XFile? file = await _picker.pickImage(source: ImageSource.gallery);
      if (file == null) return;
      await _processPickedFiles([file]);
    } catch (e) {
      _showError('Failed to pick image: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickSingleVideo() async {
    setState(() => _isLoading = true);
    try {
      final XFile? file = await _picker.pickVideo(source: ImageSource.gallery);
      if (file == null) return;
      await _processPickedFiles([file]);
    } catch (e) {
      _showError('Failed to pick video: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _processPickedFiles(List<XFile> files) async {
    int addedCount = 0;
    int skippedCount = 0;

    for (final xFile in files) {
      final file = File(xFile.path);
      if (!await file.exists()) {
        skippedCount++;
        continue;
      }

      final size = await file.length();
      final mime = FileUtils.getMimeType(xFile.path);
      final isImg = FileUtils.isImage(xFile.path);
      final isVid = FileUtils.isVideo(xFile.path);

      if (!isImg && !isVid) {
        skippedCount++;
        continue;
      }

      // Check if already in current list
      final alreadyPresent = _selectedItems.any((i) => i.path == xFile.path);
      if (!alreadyPresent) {
        _selectedItems.add(
          SelectedMediaItem(
            path: xFile.path,
            name: xFile.name.isNotEmpty ? xFile.name : xFile.path.split(Platform.pathSeparator).last,
            size: size,
            mimeType: mime,
            isVideo: isVid,
          ),
        );
        addedCount++;
      }
    }

    if (mounted) {
      setState(() {});
      if (skippedCount > 0) {
        _showInfo('Added $addedCount item(s). $skippedCount unsupported or duplicate files skipped.');
      } else if (addedCount > 0) {
        _showSuccess('Added $addedCount item(s) to selection');
      }
    }
  }

  void _removeItem(int index) {
    setState(() {
      _selectedItems.removeAt(index);
    });
  }

  void _clearAll() {
    setState(() {
      _selectedItems.clear();
    });
  }

  void _previewItem(SelectedMediaItem item) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MediaPreviewScreen(
          filePath: item.path,
          isVideo: item.isVideo,
        ),
      ),
    );
  }

  void _addAllToUploadQueue() {
    if (_selectedItems.isEmpty) return;

    final uploadItems = _selectedItems.map((selected) {
      return UploadItem(
        id: DateTime.now().microsecondsSinceEpoch.toString() + selected.name.hashCode.toString(),
        filePath: selected.path,
        fileName: selected.name,
        fileSize: selected.size,
        mimeType: selected.mimeType,
        isVideo: selected.isVideo,
        description: 'Selected from gallery',
        createdAt: DateTime.now(),
      );
    }).toList();

    context.read<UploadBloc>().add(UploadQueueAdded(uploadItems));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Added ${_selectedItems.length} item(s) to upload queue'),
        backgroundColor: AppTheme.successColor,
        behavior: SnackBarBehavior.floating,
      ),
    );

    Navigator.of(context).pop();
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppTheme.errorColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showInfo(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showSuccess(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppTheme.successColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gallery Media Picker'),
        actions: [
          if (_selectedItems.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_outlined),
              tooltip: 'Clear selection',
              onPressed: _clearAll,
            ),
        ],
      ),
      body: Column(
        children: [
          // Picker Action Buttons Card
          Container(
            padding: const EdgeInsets.all(16.0),
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _pickMultipleMedia,
                  icon: const Icon(Icons.perm_media_outlined),
                  label: const Text('Select Multiple Media (Photos & Videos)'),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _isLoading ? null : _pickSingleImage,
                        icon: const Icon(Icons.image_outlined, size: 18),
                        label: const Text('Pick Image'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _isLoading ? null : _pickSingleVideo,
                        icon: const Icon(Icons.video_library_outlined, size: 18),
                        label: const Text('Pick Video'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Header summary
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Selected Files (${_selectedItems.length})',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                if (_selectedItems.isNotEmpty)
                  Text(
                    'Total: ${FileUtils.formatFileSize(_selectedItems.fold(0, (sum, i) => sum + i.size))}',
                    style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                  ),
              ],
            ),
          ),

          // Selected Items List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _selectedItems.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.photo_library_outlined, size: 56, color: Colors.grey.shade400),
                            const SizedBox(height: 14),
                            Text(
                              'No media selected yet',
                              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Tap the buttons above to select from your device',
                              style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        itemCount: _selectedItems.length,
                        itemBuilder: (context, index) {
                          final item = _selectedItems[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 10),
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(10),
                              leading: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  width: 54,
                                  height: 54,
                                  color: Colors.grey.shade200,
                                  child: item.isVideo
                                      ? const Center(
                                          child: Icon(Icons.videocam, color: AppTheme.primaryColor),
                                        )
                                      : Image.file(
                                          File(item.path),
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image),
                                        ),
                                ),
                              ),
                              title: Text(
                                item.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: item.isVideo ? Colors.purple.shade50 : Colors.blue.shade50,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        item.mimeType,
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: item.isVideo ? Colors.purple.shade800 : Colors.blue.shade800,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      FileUtils.formatFileSize(item.size),
                                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                    ),
                                  ],
                                ),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.visibility_outlined, size: 20),
                                    tooltip: 'Preview',
                                    onPressed: () => _previewItem(item),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.close, color: Colors.red, size: 20),
                                    tooltip: 'Remove',
                                    onPressed: () => _removeItem(index),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),

          // Bottom Add All to Queue Button
          if (_selectedItems.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: SafeArea(
                top: false,
                child: ElevatedButton.icon(
                  onPressed: _addAllToUploadQueue,
                  icon: const Icon(Icons.cloud_upload_outlined),
                  label: Text('Add ${_selectedItems.length} Item(s) to Upload Queue'),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
