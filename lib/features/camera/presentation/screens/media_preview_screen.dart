import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:video_player/video_player.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/file_utils.dart';
import '../../../upload/data/models/upload_item.dart';
import '../../../upload/presentation/bloc/upload_bloc.dart';
import '../../../upload/presentation/bloc/upload_event.dart';

class MediaPreviewScreen extends StatefulWidget {
  final String filePath;
  final bool isVideo;

  const MediaPreviewScreen({
    super.key,
    required this.filePath,
    required this.isVideo,
  });

  @override
  State<MediaPreviewScreen> createState() => _MediaPreviewScreenState();
}

class _MediaPreviewScreenState extends State<MediaPreviewScreen> {
  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;
  int _fileSizeBytes = 0;
  final TextEditingController _descController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadFileMeta();
    if (widget.isVideo) {
      _initVideo();
    }
  }

  Future<void> _loadFileMeta() async {
    final size = await FileUtils.getFileSize(widget.filePath);
    if (mounted) {
      setState(() {
        _fileSizeBytes = size;
      });
    }
  }

  Future<void> _initVideo() async {
    _videoController = VideoPlayerController.file(File(widget.filePath));
    try {
      await _videoController!.initialize();
      _videoController!.setLooping(true);
      await _videoController!.play();
      if (mounted) {
        setState(() {
          _isVideoInitialized = true;
        });
      }
    } catch (e) {
      debugPrint('Video init failed: $e');
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _descController.dispose();
    super.dispose();
  }

  void _acceptMedia() {
    final fileName = widget.filePath.split(Platform.pathSeparator).last;
    final mimeType = FileUtils.getMimeType(widget.filePath);

    final item = UploadItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      filePath: widget.filePath,
      fileName: fileName,
      fileSize: _fileSizeBytes,
      mimeType: mimeType,
      isVideo: widget.isVideo,
      description: _descController.text.trim(),
      createdAt: DateTime.now(),
    );

    context.read<UploadBloc>().add(UploadQueueAdded([item]));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Added "$fileName" to upload queue'),
        backgroundColor: AppTheme.successColor,
        behavior: SnackBarBehavior.floating,
      ),
    );

    // Pop preview and return accepted flag
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final fileName = widget.filePath.split(Platform.pathSeparator).last;
    final formattedSize = FileUtils.formatFileSize(_fileSizeBytes);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(widget.isVideo ? 'Video Preview' : 'Photo Preview'),
        backgroundColor: Colors.black.withValues(alpha: 0.85),
      ),
      body: Column(
        children: [
          // Media Player / Viewer
          Expanded(
            child: Center(
              child: widget.isVideo
                  ? (_isVideoInitialized && _videoController != null
                      ? AspectRatio(
                          aspectRatio: _videoController!.value.aspectRatio,
                          child: Stack(
                            alignment: Alignment.bottomCenter,
                            children: [
                              VideoPlayer(_videoController!),
                              _VideoControlsOverlay(controller: _videoController!),
                              VideoProgressIndicator(
                                _videoController!,
                                allowScrubbing: true,
                                colors: const VideoProgressColors(
                                  playedColor: AppTheme.primaryColor,
                                  bufferedColor: Colors.white24,
                                  backgroundColor: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        )
                      : const CircularProgressIndicator(color: Colors.white))
                  : InteractiveViewer(
                      child: Image.file(
                        File(widget.filePath),
                        fit: BoxFit.contain,
                      ),
                    ),
            ),
          ),

          // Metadata and Action Bar
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.grey.shade900,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Icon(
                        widget.isVideo ? Icons.videocam : Icons.photo,
                        color: Colors.white70,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          fileName,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.white12,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          formattedSize,
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _descController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Add an optional description...',
                      hintStyle: const TextStyle(color: Colors.white54, fontSize: 13),
                      filled: true,
                      fillColor: Colors.white10,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Colors.white38),
                          ),
                          onPressed: () {
                            // Discard and retake
                            Navigator.of(context).pop(false);
                          },
                          icon: const Icon(Icons.refresh),
                          label: const Text('Retake'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                          ),
                          onPressed: _acceptMedia,
                          icon: const Icon(Icons.check),
                          label: const Text('Accept & Add'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _VideoControlsOverlay extends StatefulWidget {
  final VideoPlayerController controller;

  const _VideoControlsOverlay({required this.controller});

  @override
  State<_VideoControlsOverlay> createState() => _VideoControlsOverlayState();
}

class _VideoControlsOverlayState extends State<_VideoControlsOverlay> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        setState(() {
          widget.controller.value.isPlaying
              ? widget.controller.pause()
              : widget.controller.play();
        });
      },
      child: Center(
        child: AnimatedOpacity(
          opacity: widget.controller.value.isPlaying ? 0.0 : 0.8,
          duration: const Duration(milliseconds: 200),
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.black54,
              shape: BoxShape.circle,
            ),
            padding: const EdgeInsets.all(14),
            child: Icon(
              widget.controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
              color: Colors.white,
              size: 44,
            ),
          ),
        ),
      ),
    );
  }
}
