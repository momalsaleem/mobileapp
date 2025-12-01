import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';

class CameraPage extends StatefulWidget {
  const CameraPage({super.key});

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> with WidgetsBindingObserver {
  CameraController? _cameraController;
  bool _isCameraInitialized = false;
  bool _hasCameraError = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeCamera();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      _stopCamera();
    } else if (state == AppLifecycleState.resumed) {
      _startCamera();
    }
  }

  Future<void> _initializeCamera() async {
    try {
      setState(() {
        _hasCameraError = false;
      });

      // Guard for web
      if (kIsWeb) {
        _handleCameraError('Camera on web is not supported in this flow.');
        return;
      }

      // Request camera permission
      final permissionStatus = await Permission.camera.request();
      if (!permissionStatus.isGranted) {
        _handleCameraError('Camera permission denied');
        return;
      }

      final cameras = await availableCameras();
      
      if (cameras.isEmpty) {
        throw Exception('No cameras available');
      }

      // Prefer back camera
      final CameraDescription camera = cameras.firstWhere(
        (CameraDescription camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      final controller = CameraController(
        camera,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: Platform.isAndroid
            ? ImageFormatGroup.yuv420
            : ImageFormatGroup.bgra8888,
      );

      // Add listener for camera errors
      controller.addListener(() {
        if (controller.value.hasError) {
          _handleCameraError(controller.value.errorDescription);
        }
      });

      try {
        await controller.initialize();
      } on CameraException catch (e) {
        _handleCameraError('Camera initialize failed: ${e.description}');
        return;
      }

      if (mounted) {
        setState(() {
          _cameraController = controller;
          _isCameraInitialized = true;
        });
      }

      await _startCamera();
    } catch (e) {
      _handleCameraError(e.toString());
    }
  }

  Future<void> _startCamera() async {
    if (_cameraController == null) return;

    if (!_cameraController!.value.isInitialized) {
      try {
        await _cameraController!.initialize();
      } catch (e) {
        _handleCameraError('Failed to initialize camera controller: $e');
        return;
      }
    }

    if (_cameraController!.value.isStreamingImages) return;

    try {
      await _cameraController!.startImageStream((image) {
        // Simple camera preview - no image processing
      });
    } catch (e) {
      _handleCameraError(e.toString());
    }
  }

  Future<void> _stopCamera() async {
    if (_cameraController != null) {
      try {
        if (_cameraController!.value.isStreamingImages) {
          await _cameraController!.stopImageStream();
        }
      } catch (e) {
        debugPrint('Error stopping camera stream: $e');
      }
    }
  }

  void _handleCameraError(String? error) {
    if (mounted) {
      setState(() {
        _hasCameraError = true;
        _isCameraInitialized = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Camera error: ${error ?? 'Unknown error'}'),
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: 'Retry',
            onPressed: _retryCamera,
          ),
        ),
      );
    }
  }

  Future<void> _retryCamera() async {
    await _stopCamera();
    try {
      await _cameraController?.dispose();
    } catch (e) {
      debugPrint('Error disposing controller: $e');
    }
    
    setState(() {
      _cameraController = null;
      _isCameraInitialized = false;
      _hasCameraError = false;
    });
    
    await _initializeCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopCamera();
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text(
          'Camera',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.black,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
        actions: [
          if (_hasCameraError)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _retryCamera,
              tooltip: 'Retry Camera',
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_hasCameraError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.camera_alt,
              size: 64,
              color: Colors.white54,
            ),
            const SizedBox(height: 16),
            const Text(
              'Camera unavailable',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
            const SizedBox(height: 8),
            const Text(
              'Please check camera permissions',
              style: TextStyle(color: Colors.white54),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _retryCamera,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    if (!_isCameraInitialized) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
            ),
            SizedBox(height: 16),
            Text(
              'Initializing Camera...',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
      );
    }

    return CameraPreview(_cameraController!);
  }
}