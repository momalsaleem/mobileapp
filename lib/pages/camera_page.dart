import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_object_detection/google_mlkit_object_detection.dart';

class CameraPage extends StatefulWidget {
  const CameraPage({super.key});

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> with WidgetsBindingObserver {
  CameraController? _cameraController;
  ObjectDetector? _objectDetector;
  bool _isProcessingFrame = false;
  bool _isCameraInitialized = false;
  bool _hasCameraError = false;
  List<String> _detectedLabels = <String>[];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();
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

      final cameras = await availableCameras();
      
      if (cameras.isEmpty) {
        throw Exception('No cameras available');
      }

      // Prefer back camera, fall back to any available camera
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

      await controller.initialize();

      // Initialize object detector
      final options = ObjectDetectorOptions(
        mode: DetectionMode.stream,
        classifyObjects: true,
        multipleObjects: true,
      );
      final detector = ObjectDetector(options: options);

      if (mounted) {
        setState(() {
          _cameraController = controller;
          _objectDetector = detector;
          _isCameraInitialized = true;
        });
      }

      await _startCamera();
    } catch (e) {
      _handleCameraError(e.toString());
    }
  }

  Future<void> _startCamera() async {
    if (_cameraController != null && _cameraController!.value.isInitialized) {
      try {
        await _cameraController!.startImageStream(_processCameraImage);
      } catch (e) {
        _handleCameraError(e.toString());
      }
    }
  }

  Future<void> _stopCamera() async {
    if (_cameraController != null && _cameraController!.value.isStreamingImages) {
      await _cameraController!.stopImageStream();
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
    await _cameraController?.dispose();
    await _objectDetector?.close();
    
    setState(() {
      _cameraController = null;
      _objectDetector = null;
      _isCameraInitialized = false;
      _hasCameraError = false;
    });
    
    await _initializeCamera();
  }

  Future<void> _processCameraImage(CameraImage image) async {
    if (_isProcessingFrame || _objectDetector == null || !mounted) return;
    
    _isProcessingFrame = true;

    try {
      final inputImage = _toInputImage(image, _cameraController!);
      final objects = await _objectDetector!.processImage(inputImage);

      final labels = <String>{};
      for (final obj in objects) {
        for (final label in obj.labels) {
          final trimmedLabel = label.text.trim();
          if (trimmedLabel.isNotEmpty && label.confidence > 0.5) {
            labels.add('${trimmedLabel} (${(label.confidence * 100).toStringAsFixed(1)}%)');
          }
        }
      }

      if (mounted) {
        setState(() {
          _detectedLabels = labels.toList()..sort();
        });
      }
    } catch (e) {
      // Ignore occasional frame processing errors to keep stream alive
      debugPrint('Frame processing error: $e');
    } finally {
      _isProcessingFrame = false;
    }
  }

  InputImage _toInputImage(CameraImage image, CameraController controller) {
    final camera = controller.description;
    final rotation = _rotationIntToImageRotation(camera.sensorOrientation);

    if (Platform.isAndroid) {
      return InputImage.fromBytes(
        bytes: image.planes[0].bytes,
        metadata: InputImageMetadata(
          size: Size(image.width.toDouble(), image.height.toDouble()),
          rotation: rotation,
          format: InputImageFormat.yuv420,
          bytesPerRow: image.planes[0].bytesPerRow,
        ),
      );
    } else {
      // iOS
      return InputImage.fromBytes(
        bytes: image.planes[0].bytes,
        metadata: InputImageMetadata(
          size: Size(image.width.toDouble(), image.height.toDouble()),
          rotation: rotation,
          format: InputImageFormat.bgra8888,
          bytesPerRow: image.planes[0].bytesPerRow,
        ),
      );
    }
  }

  InputImageRotation _rotationIntToImageRotation(int rotation) {
    switch (rotation) {
      case 90:
        return InputImageRotation.rotation90deg;
      case 180:
        return InputImageRotation.rotation180deg;
      case 270:
        return InputImageRotation.rotation270deg;
      case 0:
      default:
        return InputImageRotation.rotation0deg;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopCamera();
    _cameraController?.dispose();
    _objectDetector?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0d1b2a),
      appBar: AppBar(
        title: const Text(
          'Object Detection',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF0d1b2a),
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
              Icons.error_outline, // Fixed: Changed from camera_off to error_outline
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
                backgroundColor: const Color(0xFF1349EC),
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
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1349EC)),
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

    return Stack(
      children: [
        Positioned.fill(
          child: CameraPreview(_cameraController!),
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.7),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Detected Objects:',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _detectedLabels.isEmpty
                      ? 'No objects detected'
                      : _detectedLabels.join(', '),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}