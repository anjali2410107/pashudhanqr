import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../../core/theme/app_theme.dart';
import 'media_preview_screen.dart';

enum CameraCaptureMode { photo, video }

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen>
    with WidgetsBindingObserver {
  List<CameraDescription> _cameras = [];
  CameraController? _controller;
  int _selectedCameraIndex = 0;
  bool _isCameraInitialized = false;
  bool _isPermissionDenied = false;
  String _permissionErrorMessage = '';

  CameraCaptureMode _captureMode = CameraCaptureMode.photo;
  bool _isRecordingVideo = false;
  Timer? _recordTimer;
  int _recordSeconds = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkPermissionsAndInit();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final CameraController? cameraController = _controller;
    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive || state == AppLifecycleState.paused) {
      // Free camera resource when app goes to background
      cameraController.dispose();
      _controller = null;
      if (mounted) {
        setState(() {
          _isCameraInitialized = false;
        });
      }
    } else if (state == AppLifecycleState.resumed) {
      _initCameraController(_selectedCameraIndex);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _recordTimer?.cancel();
    _controller?.dispose();
    _controller = null;
    super.dispose();
  }

  Future<void> _checkPermissionsAndInit() async {
    final cameraStatus = await Permission.camera.request();
    final micStatus = await Permission.microphone.request();

    if (cameraStatus.isGranted) {
      _loadCameras();
    } else {
      if (mounted) {
        setState(() {
          _isPermissionDenied = true;
          _permissionErrorMessage = cameraStatus.isPermanentlyDenied || micStatus.isPermanentlyDenied
              ? 'Permissions are permanently denied. Please enable Camera and Microphone in system settings.'
              : 'Camera and microphone permissions are required to capture photos and videos.';
        });
      }
    }
  }

  Future<void> _loadCameras() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isNotEmpty) {
        await _initCameraController(0);
      } else {
        if (mounted) {
          setState(() {
            _isPermissionDenied = true;
            _permissionErrorMessage = 'No camera hardware found on this device.';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isPermissionDenied = true;
          _permissionErrorMessage = 'Failed to load camera: $e';
        });
      }
    }
  }

  Future<void> _initCameraController(int cameraIndex) async {
    if (_cameras.isEmpty) return;

    final previousController = _controller;
    await previousController?.dispose();

    final newController = CameraController(
      _cameras[cameraIndex],
      ResolutionPreset.high,
      enableAudio: true,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    _controller = newController;

    try {
      await newController.initialize();
      if (mounted) {
        setState(() {
          _selectedCameraIndex = cameraIndex;
          _isCameraInitialized = true;
          _isPermissionDenied = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isCameraInitialized = false;
          _isPermissionDenied = true;
          _permissionErrorMessage = 'Camera init failed: $e';
        });
      }
    }
  }

  void _switchCamera() {
    if (_cameras.length < 2) return;
    final nextIndex = (_selectedCameraIndex + 1) % _cameras.length;
    _initCameraController(nextIndex);
  }

  Future<void> _takePhoto() async {
    if (_controller == null || !_controller!.value.isInitialized) return;
    try {
      final xFile = await _controller!.takePicture();
      _navigateToPreview(xFile.path, isVideo: false);
    } catch (e) {
      _showError('Photo capture failed: $e');
    }
  }

  Future<void> _startVideoRecording() async {
    if (_controller == null || !_controller!.value.isInitialized) return;
    if (_controller!.value.isRecordingVideo) return;

    try {
      await _controller!.startVideoRecording();
      _recordSeconds = 0;
      _recordTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (mounted) {
          setState(() {
            _recordSeconds++;
          });
        }
      });
      if (mounted) {
        setState(() {
          _isRecordingVideo = true;
        });
      }
    } catch (e) {
      _showError('Failed to start recording: $e');
    }
  }

  Future<void> _stopVideoRecording() async {
    if (_controller == null || !_controller!.value.isRecordingVideo) return;

    _recordTimer?.cancel();
    try {
      final xFile = await _controller!.stopVideoRecording();
      if (mounted) {
        setState(() {
          _isRecordingVideo = false;
        });
      }
      _navigateToPreview(xFile.path, isVideo: true);
    } catch (e) {
      _showError('Failed to stop recording: $e');
    }
  }

  void _navigateToPreview(String filePath, {required bool isVideo}) async {
    final accepted = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => MediaPreviewScreen(
          filePath: filePath,
          isVideo: isVideo,
        ),
      ),
    );

    if (accepted == true && mounted) {
      // Pop camera screen back to dashboard/uploads
      Navigator.of(context).pop();
    }
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

  String _formatTimer(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    if (_isPermissionDenied) {
      return Scaffold(
        appBar: AppBar(title: const Text('Camera')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(28.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.no_photography_outlined, size: 64, color: Colors.grey.shade600),
                const SizedBox(height: 18),
                Text(
                  'Camera Access Needed',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Text(
                  _permissionErrorMessage,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () async {
                    await openAppSettings();
                    _checkPermissionsAndInit();
                  },
                  icon: const Icon(Icons.settings),
                  label: const Text('Open App Settings'),
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: _checkPermissionsAndInit,
                  child: const Text('Retry Permission'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (!_isCameraInitialized || _controller == null) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Camera Live Preview
          Center(
            child: CameraPreview(_controller!),
          ),

          // Top Header Bar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white, size: 28),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    if (_isRecordingVideo)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.fiber_manual_record, color: Colors.white, size: 14),
                            const SizedBox(width: 6),
                            Text(
                              _formatTimer(_recordSeconds),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      const SizedBox.shrink(),
                    if (_cameras.length > 1 && !_isRecordingVideo)
                      IconButton(
                        icon: const Icon(Icons.flip_camera_android, color: Colors.white, size: 26),
                        onPressed: _switchCamera,
                      )
                    else
                      const SizedBox(width: 48),
                  ],
                ),
              ),
            ),
          ),

          // Bottom Controls
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Mode Selector: Photo / Video
                  if (!_isRecordingVideo)
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildModeChip(CameraCaptureMode.photo, 'PHOTO', Icons.photo_camera),
                          _buildModeChip(CameraCaptureMode.video, 'VIDEO', Icons.videocam),
                        ],
                      ),
                    ),

                  // Trigger Button
                  Padding(
                    padding: const EdgeInsets.only(bottom: 24.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (_captureMode == CameraCaptureMode.photo)
                          GestureDetector(
                            onTap: _takePhoto,
                            child: Container(
                              width: 76,
                              height: 76,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 4),
                                color: Colors.white.withValues(alpha: 0.3),
                              ),
                              child: Center(
                                child: Container(
                                  width: 58,
                                  height: 58,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          )
                        else
                          GestureDetector(
                            onTap: _isRecordingVideo ? _stopVideoRecording : _startVideoRecording,
                            child: Container(
                              width: 76,
                              height: 76,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 4),
                                color: Colors.red.withValues(alpha: 0.3),
                              ),
                              child: Center(
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  width: _isRecordingVideo ? 30 : 58,
                                  height: _isRecordingVideo ? 30 : 58,
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    borderRadius: BorderRadius.circular(_isRecordingVideo ? 6 : 30),
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeChip(CameraCaptureMode mode, String label, IconData icon) {
    final isSelected = _captureMode == mode;
    return GestureDetector(
      onTap: () {
        if (_captureMode != mode) {
          setState(() {
            _captureMode = mode;
          });
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: isSelected ? Colors.white : Colors.white70),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white70,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
