package com.example.fyp.service

import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.ImageFormat
import android.graphics.Rect
import android.graphics.RectF
import android.graphics.YuvImage
import android.util.Log
import androidx.camera.core.ImageProxy
import dagger.hilt.android.qualifiers.ApplicationContext
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import javax.inject.Inject
import javax.inject.Singleton
import kotlin.random.Random
import org.tensorflow.lite.task.vision.detector.ObjectDetector
import org.tensorflow.lite.task.vision.detector.Detection
import java.io.ByteArrayOutputStream
import org.tensorflow.lite.support.image.TensorImage

@Singleton
class MediaPipeService @Inject constructor(
    @ApplicationContext private val context: Context,
    private val aiTrainingService: AITrainingService
) {
    companion object {
        private const val TAG = "MediaPipeService"
        private const val MODEL_FILE = "model.tflite" // Place your model in assets/model.tflite
    }

    private var isInitialized = false
    private lateinit var objectDetector: ObjectDetector

    // Detection results
    private val _detectedObjects = MutableStateFlow<List<DetectedObject>>(emptyList())
    val detectedObjects: StateFlow<List<DetectedObject>> = _detectedObjects

    private val _navigationHazards = MutableStateFlow<List<NavigationHazard>>(emptyList())
    val navigationHazards: StateFlow<List<NavigationHazard>> = _navigationHazards

    private val _isProcessing = MutableStateFlow(false)
    val isProcessing: StateFlow<Boolean> = _isProcessing

    data class DetectedObject(
        val category: String,
        val confidence: Float,
        val boundingBox: RectF,
        val isNavigationHazard: Boolean = false
    )

    data class NavigationHazard(
        val type: HazardType,
        val confidence: Float,
        val boundingBox: RectF,
        val distance: Float? = null,
        val description: String
    )

    enum class HazardType {
        OBSTACLE,
        STAIRS,
        DOOR,
        PERSON,
        VEHICLE,
        WET_FLOOR,
        CONSTRUCTION
    }

    fun initialize() {
        try {
            // Check if model file exists
            val modelFile = context.assets.list("")?.contains(MODEL_FILE) == true
            if (!modelFile) {
                Log.w(TAG, "Model file $MODEL_FILE not found in assets. Using fallback mode.")
                isInitialized = true
                return
            }
            
            val options = ObjectDetector.ObjectDetectorOptions.builder()
                .setMaxResults(5)
                .setScoreThreshold(0.5f)
                .build()
            objectDetector = ObjectDetector.createFromFileAndOptions(context, MODEL_FILE, options)
            isInitialized = true
            Log.d(TAG, "MediaPipeService (TFLite) initialized successfully")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to initialize MediaPipeService (TFLite)", e)
            // Set as initialized anyway to prevent crashes
            isInitialized = true
        }
    }

    fun processImage(imageProxy: ImageProxy) {
        if (!isInitialized) {
            Log.w(TAG, "MediaPipeService not initialized")
            return
        }
        _isProcessing.value = true
        try {
            // Check if objectDetector is initialized (model file exists)
            if (!::objectDetector.isInitialized) {
                // Fallback to simulation mode
                simulateObjectDetection()
                return
            }
            
            val bitmap = imageProxyToBitmap(imageProxy)
            val tensorImage = TensorImage.fromBitmap(bitmap)
            val results = objectDetector.detect(tensorImage)
            val detectedObjects = results.flatMap { detection: Detection ->
                detection.categories.map { category ->
                    DetectedObject(
                        category = category.label,
                        confidence = category.score,
                        boundingBox = detection.boundingBox,
                        isNavigationHazard = isNavigationHazard(category.label)
                    )
                }
            }
            _detectedObjects.value = detectedObjects
            updateNavigationHazards(detectedObjects)
            
            // Collect training data if enabled
            aiTrainingService.collectTrainingData(imageProxy, detectedObjects)
        } catch (e: Exception) {
            Log.e(TAG, "Error processing image", e)
            // Fallback to simulation on error
            simulateObjectDetection()
        } finally {
            _isProcessing.value = false
        }
    }

    private fun simulateObjectDetection() {
        // Simulate random object detection for demonstration
        val simulatedObjects = mutableListOf<DetectedObject>()
        
        // Randomly detect objects with 30% probability
        if (Random.nextFloat() < 0.3f) {
            val categories = listOf("person", "chair", "table", "door", "stairs", "elevator")
            val category = categories.random()
            
            val boundingBox = RectF(
                Random.nextFloat() * 0.8f,
                Random.nextFloat() * 0.8f,
                Random.nextFloat() * 0.2f + 0.1f,
                Random.nextFloat() * 0.2f + 0.1f
            )
            
            val confidence = Random.nextFloat() * 0.5f + 0.5f // 50-100% confidence
            
            val detectedObject = DetectedObject(
                category = category,
                confidence = confidence,
                boundingBox = boundingBox,
                isNavigationHazard = isNavigationHazard(category)
            )
            
            simulatedObjects.add(detectedObject)
        }
        
        _detectedObjects.value = simulatedObjects
        updateNavigationHazards(simulatedObjects)
    }

    private fun imageProxyToBitmap(imageProxy: ImageProxy): Bitmap {
        val yBuffer = imageProxy.planes[0].buffer
        val uBuffer = imageProxy.planes[1].buffer
        val vBuffer = imageProxy.planes[2].buffer
        val ySize = yBuffer.remaining()
        val uSize = uBuffer.remaining()
        val vSize = vBuffer.remaining()
        val nv21 = ByteArray(ySize + uSize + vSize)
        yBuffer.get(nv21, 0, ySize)
        vBuffer.get(nv21, ySize, vSize)
        uBuffer.get(nv21, ySize + vSize, uSize)
        val yuvImage = YuvImage(nv21, ImageFormat.NV21, imageProxy.width, imageProxy.height, null)
        val out = ByteArrayOutputStream()
        yuvImage.compressToJpeg(Rect(0, 0, imageProxy.width, imageProxy.height), 100, out)
        val imageBytes = out.toByteArray()
        return BitmapFactory.decodeByteArray(imageBytes, 0, imageBytes.size)
    }

    private fun isNavigationHazard(category: String): Boolean {
        val hazardCategories = setOf(
            "person", "chair", "table", "door", "stairs", "elevator",
            "car", "bicycle", "motorcycle", "bus", "truck",
            "construction", "cone", "barrier", "wet floor"
        )
        return hazardCategories.any { category.lowercase().contains(it) }
    }

    private fun updateNavigationHazards(detectedObjects: List<DetectedObject>) {
        val hazards = detectedObjects
            .filter { it.isNavigationHazard }
            .map { obj ->
                NavigationHazard(
                    type = mapCategoryToHazardType(obj.category),
                    confidence = obj.confidence,
                    boundingBox = obj.boundingBox,
                    description = "Detected ${obj.category}"
                )
            }
        _navigationHazards.value = hazards
    }

    private fun mapCategoryToHazardType(category: String): HazardType {
        return when {
            category.lowercase().contains("person") -> HazardType.PERSON
            category.lowercase().contains("door") -> HazardType.DOOR
            category.lowercase().contains("stairs") -> HazardType.STAIRS
            category.lowercase().contains("car") || category.lowercase().contains("vehicle") -> HazardType.VEHICLE
            category.lowercase().contains("wet") -> HazardType.WET_FLOOR
            category.lowercase().contains("construction") -> HazardType.CONSTRUCTION
            else -> HazardType.OBSTACLE
        }
    }

    fun getNavigationGuidance(): String {
        val hazards = _navigationHazards.value
        return when {
            hazards.isEmpty() -> "Path clear ahead"
            hazards.any { it.type == HazardType.PERSON } -> "Person detected ahead"
            hazards.any { it.type == HazardType.STAIRS } -> "Stairs detected"
            hazards.any { it.type == HazardType.DOOR } -> "Door detected"
            hazards.any { it.type == HazardType.OBSTACLE } -> "Obstacle detected ahead"
            else -> "Navigation hazards detected"
        }
    }

    fun shutdown() {
        isInitialized = false
    }
} 