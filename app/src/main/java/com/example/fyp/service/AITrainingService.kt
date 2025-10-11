package com.example.fyp.service

import android.content.Context
import android.graphics.Bitmap
import android.graphics.RectF
import android.util.Log
import androidx.camera.core.ImageProxy
import dagger.hilt.android.qualifiers.ApplicationContext
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import javax.inject.Inject
import javax.inject.Singleton
import java.io.File
import java.io.FileOutputStream
import java.text.SimpleDateFormat
import java.util.*
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import org.json.JSONObject
import org.json.JSONArray

@Singleton
class AITrainingService @Inject constructor(
    @ApplicationContext private val context: Context
) {
    companion object {
        private const val TAG = "AITrainingService"
        private const val TRAINING_DATA_DIR = "ai_training_data"
        private const val ANNOTATIONS_FILE = "annotations.json"
        private const val IMAGES_DIR = "images"
        private const val MAX_TRAINING_IMAGES = 1000 // Limit to prevent storage issues
    }

    private val _isCollectingData = MutableStateFlow(false)
    val isCollectingData: StateFlow<Boolean> = _isCollectingData

    private val _collectedImagesCount = MutableStateFlow(0)
    val collectedImagesCount: StateFlow<Int> = _collectedImagesCount

    private val _trainingProgress = MutableStateFlow(0f)
    val trainingProgress: StateFlow<Float> = _trainingProgress

    private val annotations = mutableListOf<TrainingAnnotation>()
    private val trainingDataDir: File
    private val imagesDir: File

    init {
        trainingDataDir = File(context.filesDir, TRAINING_DATA_DIR)
        imagesDir = File(trainingDataDir, IMAGES_DIR)
        createDirectories()
        loadAnnotations()
    }

    private fun createDirectories() {
        trainingDataDir.mkdirs()
        imagesDir.mkdirs()
    }

    private fun loadAnnotations() {
        val annotationsFile = File(trainingDataDir, ANNOTATIONS_FILE)
        if (annotationsFile.exists()) {
            try {
                val jsonString = annotationsFile.readText()
                val jsonArray = JSONArray(jsonString)
                annotations.clear()
                for (i in 0 until jsonArray.length()) {
                    val annotation = parseAnnotation(jsonArray.getJSONObject(i))
                    annotations.add(annotation)
                }
                _collectedImagesCount.value = annotations.size
                Log.d(TAG, "Loaded ${annotations.size} annotations")
            } catch (e: Exception) {
                Log.e(TAG, "Error loading annotations", e)
            }
        }
    }

    private fun parseAnnotation(json: JSONObject): TrainingAnnotation {
        return TrainingAnnotation(
            imagePath = json.getString("image_path"),
            objects = json.getJSONArray("objects").let { array ->
                (0 until array.length()).map { i ->
                    val obj = array.getJSONObject(i)
                    DetectedObject(
                        category = obj.getString("category"),
                        confidence = obj.getDouble("confidence").toFloat(),
                        boundingBox = RectF(
                            obj.getDouble("left").toFloat(),
                            obj.getDouble("top").toFloat(),
                            obj.getDouble("right").toFloat(),
                            obj.getDouble("bottom").toFloat()
                        ),
                        isNavigationHazard = obj.getBoolean("is_navigation_hazard")
                    )
                }
            },
            timestamp = json.getLong("timestamp"),
            location = json.optString("location", ""),
            userCorrection = json.optString("user_correction", "")
        )
    }

    fun startDataCollection() {
        if (_collectedImagesCount.value >= MAX_TRAINING_IMAGES) {
            Log.w(TAG, "Maximum training images reached")
            return
        }
        _isCollectingData.value = true
        Log.d(TAG, "Started AI training data collection")
    }

    fun stopDataCollection() {
        _isCollectingData.value = false
        Log.d(TAG, "Stopped AI training data collection")
    }

    fun collectTrainingData(
        imageProxy: ImageProxy,
        detectedObjects: List<MediaPipeService.DetectedObject>,
        location: String = ""
    ) {
        if (!_isCollectingData.value) return
        if (_collectedImagesCount.value >= MAX_TRAINING_IMAGES) return

        CoroutineScope(Dispatchers.IO).launch {
            try {
                val timestamp = System.currentTimeMillis()
                val imageFileName = "training_${timestamp}.jpg"
                val imageFile = File(imagesDir, imageFileName)

                // Convert ImageProxy to Bitmap and save
                val bitmap = imageProxyToBitmap(imageProxy)
                val outputStream = FileOutputStream(imageFile)
                bitmap.compress(Bitmap.CompressFormat.JPEG, 90, outputStream)
                outputStream.close()

                // Create annotation
                val annotation = TrainingAnnotation(
                    imagePath = imageFileName,
                    objects = detectedObjects.map { obj ->
                        DetectedObject(
                            category = obj.category,
                            confidence = obj.confidence,
                            boundingBox = obj.boundingBox,
                            isNavigationHazard = obj.isNavigationHazard
                        )
                    },
                    timestamp = timestamp,
                    location = location,
                    userCorrection = ""
                )

                annotations.add(annotation)
                saveAnnotations()

                withContext(Dispatchers.Main) {
                    _collectedImagesCount.value = annotations.size
                }

                Log.d(TAG, "Collected training data: ${imageFileName} with ${detectedObjects.size} objects")
            } catch (e: Exception) {
                Log.e(TAG, "Error collecting training data", e)
            }
        }
    }

    fun addUserCorrection(
        imagePath: String,
        corrections: List<UserCorrection>
    ) {
        val annotation = annotations.find { it.imagePath == imagePath }
        annotation?.let {
            val correctionText = corrections.joinToString("; ") { correction ->
                "${correction.originalCategory} -> ${correction.correctedCategory} (${correction.confidence})"
            }
            it.userCorrection = correctionText
            saveAnnotations()
            Log.d(TAG, "Added user correction for $imagePath")
        }
    }

    fun getTrainingDataStats(): TrainingDataStats {
        val totalImages = annotations.size
        val totalObjects = annotations.sumOf { it.objects.size }
        val uniqueCategories = annotations.flatMap { it.objects }
            .map { it.category }
            .distinct()
            .size
        val hazardCount = annotations.flatMap { it.objects }
            .count { it.isNavigationHazard }
        val correctionsCount = annotations.count { it.userCorrection.isNotEmpty() }

        return TrainingDataStats(
            totalImages = totalImages,
            totalObjects = totalObjects,
            uniqueCategories = uniqueCategories,
            hazardCount = hazardCount,
            correctionsCount = correctionsCount,
            storageUsed = getTrainingDataSize()
        )
    }

    fun exportTrainingData(): File? {
        return try {
            val exportDir = File(context.getExternalFilesDir(null), "ai_training_export")
            exportDir.mkdirs()

            val timestamp = SimpleDateFormat("yyyyMMdd_HHmmss", Locale.getDefault()).format(Date())
            val zipFile = File(exportDir, "training_data_$timestamp.zip")

            // Create ZIP file with images and annotations
            createTrainingDataZip(zipFile)
            Log.d(TAG, "Training data exported to: ${zipFile.absolutePath}")
            zipFile
        } catch (e: Exception) {
            Log.e(TAG, "Error exporting training data", e)
            null
        }
    }

    private fun createTrainingDataZip(zipFile: File) {
        // Implementation for creating ZIP file
        // This would include all images and annotations.json
        // For now, we'll just copy the files
        val exportDir = zipFile.parentFile!!
        val exportImagesDir = File(exportDir, "images")
        exportImagesDir.mkdirs()

        // Copy images
        imagesDir.listFiles()?.forEach { imageFile ->
            val destFile = File(exportImagesDir, imageFile.name)
            imageFile.copyTo(destFile, overwrite = true)
        }

        // Copy annotations
        val annotationsFile = File(trainingDataDir, ANNOTATIONS_FILE)
        if (annotationsFile.exists()) {
            val destFile = File(exportDir, ANNOTATIONS_FILE)
            annotationsFile.copyTo(destFile, overwrite = true)
        }
    }

    private fun saveAnnotations() {
        try {
            val jsonArray = JSONArray()
            annotations.forEach { annotation ->
                val jsonObject = JSONObject().apply {
                    put("image_path", annotation.imagePath)
                    put("timestamp", annotation.timestamp)
                    put("location", annotation.location)
                    put("user_correction", annotation.userCorrection)
                    
                    val objectsArray = JSONArray()
                    annotation.objects.forEach { obj ->
                        val objJson = JSONObject().apply {
                            put("category", obj.category)
                            put("confidence", obj.confidence)
                            put("left", obj.boundingBox.left)
                            put("top", obj.boundingBox.top)
                            put("right", obj.boundingBox.right)
                            put("bottom", obj.boundingBox.bottom)
                            put("is_navigation_hazard", obj.isNavigationHazard)
                        }
                        objectsArray.put(objJson)
                    }
                    put("objects", objectsArray)
                }
                jsonArray.put(jsonObject)
            }

            val annotationsFile = File(trainingDataDir, ANNOTATIONS_FILE)
            annotationsFile.writeText(jsonArray.toString())
        } catch (e: Exception) {
            Log.e(TAG, "Error saving annotations", e)
        }
    }

    private fun getTrainingDataSize(): Long {
        return try {
            var totalSize = 0L
            imagesDir.listFiles()?.forEach { file ->
                totalSize += file.length()
            }
            totalSize
        } catch (e: Exception) {
            0L
        }
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
        val yuvImage = android.graphics.YuvImage(nv21, android.graphics.ImageFormat.NV21, imageProxy.width, imageProxy.height, null)
        val out = java.io.ByteArrayOutputStream()
        yuvImage.compressToJpeg(android.graphics.Rect(0, 0, imageProxy.width, imageProxy.height), 100, out)
        val imageBytes = out.toByteArray()
        return android.graphics.BitmapFactory.decodeByteArray(imageBytes, 0, imageBytes.size)
    }

    fun clearTrainingData() {
        try {
            imagesDir.listFiles()?.forEach { it.delete() }
            annotations.clear()
            val annotationsFile = File(trainingDataDir, ANNOTATIONS_FILE)
            if (annotationsFile.exists()) {
                annotationsFile.delete()
            }
            _collectedImagesCount.value = 0
            Log.d(TAG, "Training data cleared")
        } catch (e: Exception) {
            Log.e(TAG, "Error clearing training data", e)
        }
    }

    data class TrainingAnnotation(
        val imagePath: String,
        val objects: List<DetectedObject>,
        val timestamp: Long,
        val location: String,
        var userCorrection: String
    )

    data class DetectedObject(
        val category: String,
        val confidence: Float,
        val boundingBox: RectF,
        val isNavigationHazard: Boolean
    )

    data class UserCorrection(
        val originalCategory: String,
        val correctedCategory: String,
        val confidence: Float
    )

    data class TrainingDataStats(
        val totalImages: Int,
        val totalObjects: Int,
        val uniqueCategories: Int,
        val hazardCount: Int,
        val correctionsCount: Int,
        val storageUsed: Long
    )
} 