package com.example.fyp.ui.components

import android.content.Context
import android.graphics.Canvas
import android.util.AttributeSet
import android.view.SurfaceHolder
import android.view.SurfaceView
import com.google.ar.core.Frame
import com.google.ar.core.Session
import com.google.ar.core.Camera
import android.opengl.Matrix

class ARCoreView @JvmOverloads constructor(
    context: Context, attrs: AttributeSet? = null
) : SurfaceView(context, attrs), SurfaceHolder.Callback {

    private var arSession: Session? = null
    private var onFrameUpdate: ((Frame, Camera, FloatArray, FloatArray) -> Unit)? = null
    private var renderThread: Thread? = null
    private var running = false

    init {
        holder.addCallback(this)
    }

    fun setSession(session: Session) {
        arSession = session
    }

    fun setOnFrameUpdateListener(listener: (Frame, Camera, FloatArray, FloatArray) -> Unit) {
        onFrameUpdate = listener
    }

    override fun surfaceCreated(holder: SurfaceHolder) {
        running = true
        renderThread = Thread {
            while (running) {
                val session = arSession ?: continue
                val frame = session.update()
                val camera = frame.camera
                val projectionMatrix = FloatArray(16)
                val viewMatrix = FloatArray(16)
                camera.getProjectionMatrix(projectionMatrix, 0, 0.1f, 100.0f)
                camera.getViewMatrix(viewMatrix, 0)
                onFrameUpdate?.invoke(frame, camera, viewMatrix, projectionMatrix)
                // Optionally, draw camera feed to SurfaceView here (OpenGL, not shown for brevity)
                // For Compose overlay, just call onFrameUpdate and let Compose handle drawing
                try {
                    Thread.sleep(16) // ~60 FPS
                } catch (e: InterruptedException) {
                    break
                }
            }
        }
        renderThread?.start()
    }

    override fun surfaceChanged(holder: SurfaceHolder, format: Int, width: Int, height: Int) {
        // Handle surface changes if needed
    }

    override fun surfaceDestroyed(holder: SurfaceHolder) {
        running = false
        renderThread?.interrupt()
        renderThread = null
    }
} 