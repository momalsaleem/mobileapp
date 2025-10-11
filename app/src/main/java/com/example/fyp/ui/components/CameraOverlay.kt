package com.example.fyp.ui.components

import android.graphics.Color as AndroidColor
import android.graphics.Paint as AndroidPaint
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.layout.*
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Rect
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.drawscope.DrawScope
import androidx.compose.ui.graphics.drawscope.drawIntoCanvas
import androidx.compose.ui.graphics.nativeCanvas
import androidx.compose.ui.graphics.toArgb
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.unit.dp
import com.example.fyp.service.MediaPipeService
import com.example.fyp.data.entity.LocationPoint

@Composable
fun CameraOverlay(
    detectedObjects: List<MediaPipeService.DetectedObject>,
    navigationHazards: List<MediaPipeService.NavigationHazard>,
    navigationGuidance: String,
    isProcessing: Boolean,
    keypoints: List<LocationPoint> = emptyList(), // New parameter
    modifier: Modifier = Modifier
) {
    Box(modifier = modifier) {
        val density = LocalDensity.current
        // Detection bounding boxes
        Canvas(modifier = Modifier.fillMaxSize()) {
            // Draw bounding boxes for detected objects
            detectedObjects.forEach { obj ->
                val left = obj.boundingBox.left * size.width
                val top = obj.boundingBox.top * size.height
                val right = obj.boundingBox.right * size.width
                val bottom = obj.boundingBox.bottom * size.height
                val rect = Rect(
                    left = left,
                    top = top,
                    right = right,
                    bottom = bottom
                )
                val color = if (obj.isNavigationHazard) Color.Red else Color.Green
                drawRect(
                    color = color,
                    topLeft = rect.topLeft,
                    size = rect.size,
                    style = androidx.compose.ui.graphics.drawscope.Stroke(width = 4f)
                )
                // Draw label using nativeCanvas
                drawIntoCanvas { canvas ->
                    val textPaint = AndroidPaint().apply {
                        this.color = color.toArgb()
                        textSize = 32f * density.density
                        isFakeBoldText = true
                        setShadowLayer(2f, 1f, 1f, AndroidColor.BLACK)
                    }
                    canvas.nativeCanvas.drawText(
                        "${obj.category} (${(obj.confidence * 100).toInt()}%)",
                        left,
                        top - 10f,
                        textPaint
                    )
                }
            }
            // Draw keypoints as blue circles (if any)
            if (keypoints.isNotEmpty()) {
                // For demo: draw all keypoints at the center (since we don't have pixel mapping from GPS)
                keypoints.forEachIndexed { idx, _ ->
                    val cx = size.width / 2f + idx * 10f // Slight offset for visibility
                    val cy = size.height / 2f
                    drawCircle(
                        color = Color.Blue,
                        radius = 12f,
                        center = Offset(cx, cy),
                        style = androidx.compose.ui.graphics.drawscope.Fill
                    )
                }
            }
        }
        // Navigation guidance overlay
        Card(
            modifier = Modifier
                .align(Alignment.TopCenter)
                .padding(16.dp),
            colors = CardDefaults.cardColors(
                containerColor = MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.9f)
            )
        ) {
            Row(
                modifier = Modifier.padding(16.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                if (isProcessing) {
                    CircularProgressIndicator(
                        modifier = Modifier.size(20.dp),
                        strokeWidth = 2.dp
                    )
                    Spacer(modifier = Modifier.width(8.dp))
                }
                Text(
                    text = navigationGuidance,
                    style = MaterialTheme.typography.bodyMedium,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }
        }
        // Hazard count indicator
        if (navigationHazards.isNotEmpty()) {
            Card(
                modifier = Modifier
                    .align(Alignment.TopEnd)
                    .padding(16.dp),
                colors = CardDefaults.cardColors(
                    containerColor = MaterialTheme.colorScheme.errorContainer.copy(alpha = 0.9f)
                )
            ) {
                Text(
                    text = "${navigationHazards.size} hazards",
                    modifier = Modifier.padding(8.dp),
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onErrorContainer
                )
            }
        }
    }
} 