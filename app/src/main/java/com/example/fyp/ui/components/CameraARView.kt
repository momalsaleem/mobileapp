package com.example.fyp.ui.components

import android.content.Context
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.RectF
import android.util.AttributeSet
import android.view.SurfaceHolder
import android.view.SurfaceView
import androidx.camera.core.CameraSelector
import androidx.camera.core.Preview
import androidx.camera.lifecycle.ProcessCameraProvider
import androidx.camera.view.PreviewView
import androidx.core.content.ContextCompat
import androidx.lifecycle.LifecycleOwner
import com.example.fyp.data.entity.LocationPoint
import com.example.fyp.service.MediaPipeService
import kotlinx.coroutines.*
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors

class CameraARView @JvmOverloads constructor(
    context: Context, attrs: AttributeSet? = null
) : SurfaceView(context, attrs), SurfaceHolder.Callback {

    private var cameraProvider: ProcessCameraProvider? = null
    private var camera: androidx.camera.core.Camera? = null
    private var preview: Preview? = null
    private var previewView: PreviewView? = null
    private var cameraExecutor: ExecutorService = Executors.newSingleThreadExecutor()
    
    private var detectedObjects: List<MediaPipeService.DetectedObject> = emptyList()
    private var navigationHazards: List<MediaPipeService.NavigationHazard> = emptyList()
    private var keypoints: List<LocationPoint> = emptyList()
    private var navigationGuidance: String = "Path clear ahead"
    private var isProcessing: Boolean = false
    
    private val paint = Paint().apply {
        color = Color.RED
        style = Paint.Style.STROKE
        strokeWidth = 4f
        isAntiAlias = true
    }
    
    private val textPaint = Paint().apply {
        color = Color.WHITE
        textSize = 32f
        isFakeBoldText = true
        setShadowLayer(2f, 1f, 1f, Color.BLACK)
    }
    
    private val keypointPaint = Paint().apply {
        color = Color.BLUE
        style = Paint.Style.FILL
        isAntiAlias = true
    }
    
    private var renderJob: Job? = null

    init {
        holder.addCallback(this)
    }

    fun setPreviewView(previewView: PreviewView) {
        this.previewView = previewView
    }

    fun updateDetections(
        objects: List<MediaPipeService.DetectedObject>,
        hazards: List<MediaPipeService.NavigationHazard>,
        guidance: String,
        processing: Boolean
    ) {
        detectedObjects = objects
        navigationHazards = hazards
        navigationGuidance = guidance
        isProcessing = processing
    }

    fun updateKeypoints(points: List<LocationPoint>) {
        keypoints = points
    }

    override fun surfaceCreated(holder: SurfaceHolder) {
        startRendering()
    }

    override fun surfaceChanged(holder: SurfaceHolder, format: Int, width: Int, height: Int) {
        // Handle surface changes
    }

    override fun surfaceDestroyed(holder: SurfaceHolder) {
        stopRendering()
    }

    private fun startRendering() {
        renderJob = CoroutineScope(Dispatchers.Default).launch {
            while (isActive) {
                drawOverlay()
                delay(16) // ~60 FPS
            }
        }
    }

    private fun stopRendering() {
        renderJob?.cancel()
        renderJob = null
    }

    private fun drawOverlay() {
        val canvas = holder.lockCanvas()
        if (canvas != null) {
            try {
                // Clear canvas with transparency
                canvas.drawColor(Color.TRANSPARENT, android.graphics.PorterDuff.Mode.CLEAR)
                
                // Draw bounding boxes for detected objects
                detectedObjects.forEach { obj ->
                    val left = obj.boundingBox.left * width
                    val top = obj.boundingBox.top * height
                    val right = obj.boundingBox.right * width
                    val bottom = obj.boundingBox.bottom * height
                    
                    paint.color = if (obj.isNavigationHazard) Color.RED else Color.GREEN
                    canvas.drawRect(left, top, right, bottom, paint)
                    
                    // Draw label
                    textPaint.color = paint.color
                    canvas.drawText(
                        "${obj.category} (${(obj.confidence * 100).toInt()}%)",
                        left,
                        top - 10f,
                        textPaint
                    )
                }
                
                // Draw keypoints
                keypoints.forEachIndexed { idx, _ ->
                    val cx = width / 2f + idx * 20f
                    val cy = height / 2f
                    canvas.drawCircle(cx, cy, 12f, keypointPaint)
                }
                
                // Draw navigation guidance
                drawNavigationGuidance(canvas)
                
            } finally {
                holder.unlockCanvasAndPost(canvas)
            }
        }
    }

    private fun drawNavigationGuidance(canvas: Canvas) {
        val guidanceText = if (isProcessing) "Processing..." else navigationGuidance
        val textBounds = RectF()
        textPaint.getTextBounds(guidanceText, 0, guidanceText.length, android.graphics.Rect())
        
        // Draw background
        val bgPaint = Paint().apply {
            color = Color.BLACK
            alpha = 128
        }
        val padding = 20f
        val bgRect = RectF(
            width / 2f - textBounds.width() / 2f - padding,
            padding,
            width / 2f + textBounds.width() / 2f + padding,
            padding + textBounds.height() + padding
        )
        canvas.drawRect(bgRect, bgPaint)
        
        // Draw text
        textPaint.color = Color.WHITE
        canvas.drawText(
            guidanceText,
            width / 2f - textBounds.width() / 2f,
            padding + textBounds.height(),
            textPaint
        )
    }

    fun release() {
        stopRendering()
        cameraExecutor.shutdown()
    }
} 