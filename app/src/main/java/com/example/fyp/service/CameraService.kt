package com.example.fyp.service

import android.content.Context
import androidx.camera.core.*
import androidx.camera.lifecycle.ProcessCameraProvider
import androidx.camera.view.PreviewView
import androidx.core.content.ContextCompat
import androidx.lifecycle.LifecycleOwner
import dagger.hilt.android.qualifiers.ApplicationContext
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import java.io.File
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors
import javax.inject.Inject
import javax.inject.Singleton
import android.util.Log

@Singleton
class CameraService @Inject constructor(
    @ApplicationContext private val context: Context,
    private val mediaPipeService: MediaPipeService
) {
    private var imageCapture: ImageCapture? = null
    private var imageAnalysis: ImageAnalysis? = null
    private var camera: Camera? = null
    private var cameraProvider: ProcessCameraProvider? = null
    private lateinit var cameraExecutor: ExecutorService

    private val _isCameraReady = MutableStateFlow(false)
    val isCameraReady: StateFlow<Boolean> = _isCameraReady

    private val _isRecording = MutableStateFlow(false)
    val isRecording: StateFlow<Boolean> = _isRecording

    private val _errorMessage = MutableStateFlow<String?>(null)
    val errorMessage: StateFlow<String?> = _errorMessage

    init {
        cameraExecutor = Executors.newSingleThreadExecutor()
        // Initialize MediaPipe
        mediaPipeService.initialize()
    }

    fun startCamera(
        lifecycleOwner: LifecycleOwner,
        previewView: PreviewView,
        onCameraReady: () -> Unit = {}
    ) {
        try {
            val cameraProviderFuture = ProcessCameraProvider.getInstance(context)

            cameraProviderFuture.addListener({
                try {
                    cameraProvider = cameraProviderFuture.get()

                    val preview = Preview.Builder()
                        .build()
                        .also {
                            it.setSurfaceProvider(previewView.surfaceProvider)
                        }

                    imageCapture = ImageCapture.Builder()
                        .setCaptureMode(ImageCapture.CAPTURE_MODE_MINIMIZE_LATENCY)
                        .build()

                    // Add ImageAnalysis for MediaPipe processing
                    imageAnalysis = ImageAnalysis.Builder()
                        .setBackpressureStrategy(ImageAnalysis.STRATEGY_KEEP_ONLY_LATEST)
                        .setOutputImageFormat(ImageAnalysis.OUTPUT_IMAGE_FORMAT_RGBA_8888)
                        .build()
                        .also {
                            it.setAnalyzer(cameraExecutor) { imageProxy ->
                                // Process with MediaPipe
                                mediaPipeService.processImage(imageProxy)
                                imageProxy.close()
                            }
                        }

                    val cameraSelector = CameraSelector.DEFAULT_BACK_CAMERA

                    try {
                        cameraProvider?.unbindAll()
                        camera = cameraProvider?.bindToLifecycle(
                            lifecycleOwner,
                            cameraSelector,
                            preview,
                            imageCapture,
                            imageAnalysis
                        )
                        _isCameraReady.value = true
                        _errorMessage.value = null
                        onCameraReady()
                        Log.d("CameraService", "Camera started successfully with MediaPipe")
                    } catch (exc: Exception) {
                        Log.e("CameraService", "Camera binding failed", exc)
                        _errorMessage.value = "Camera binding failed: ${exc.message}"
                        _isCameraReady.value = false
                    }
                } catch (exc: Exception) {
                    Log.e("CameraService", "Camera provider initialization failed", exc)
                    _errorMessage.value = "Camera initialization failed: ${exc.message}"
                    _isCameraReady.value = false
                }
            }, ContextCompat.getMainExecutor(context))
        } catch (exc: Exception) {
            Log.e("CameraService", "Camera start failed", exc)
            _errorMessage.value = "Camera start failed: ${exc.message}"
            _isCameraReady.value = false
        }
    }

    fun takePhoto(
        outputFile: File,
        onPhotoTaken: (Boolean) -> Unit
    ) {
        val imageCapture = imageCapture ?: return

        val outputOptions = ImageCapture.OutputFileOptions.Builder(outputFile).build()

        imageCapture.takePicture(
            outputOptions,
            ContextCompat.getMainExecutor(context),
            object : ImageCapture.OnImageSavedCallback {
                override fun onImageSaved(output: ImageCapture.OutputFileResults) {
                    onPhotoTaken(true)
                }

                override fun onError(exc: ImageCaptureException) {
                    Log.e("CameraService", "Photo capture failed", exc)
                    onPhotoTaken(false)
                }
            }
        )
    }

    fun startRecording() {
        _isRecording.value = true
        // Additional recording logic can be added here
    }

    fun stopRecording() {
        _isRecording.value = false
        // Additional recording stop logic can be added here
    }

    fun toggleFlash() {
        camera?.let { camera ->
            if (camera.cameraInfo.hasFlashUnit()) {
                camera.cameraControl.enableTorch(
                    !(camera.cameraInfo.torchState.value == TorchState.ON)
                )
            }
        }
    }

    fun setZoomLevel(zoomLevel: Float) {
        camera?.cameraControl?.setZoomRatio(zoomLevel)
    }

    fun getCameraInfo(): CameraInfo? {
        return camera?.cameraInfo
    }

    fun isFlashAvailable(): Boolean {
        return camera?.cameraInfo?.hasFlashUnit() ?: false
    }

    fun clearError() {
        _errorMessage.value = null
    }

    // MediaPipe integration methods
    fun getDetectedObjects() = mediaPipeService.detectedObjects
    fun getNavigationHazards() = mediaPipeService.navigationHazards
    fun isProcessing() = mediaPipeService.isProcessing
    fun getNavigationGuidance() = mediaPipeService.getNavigationGuidance()

    fun shutdown() {
        cameraExecutor.shutdown()
        mediaPipeService.shutdown()
    }
} 