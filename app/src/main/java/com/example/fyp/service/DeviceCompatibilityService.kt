package com.example.fyp.service

import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import android.util.Log
import dagger.hilt.android.qualifiers.ApplicationContext
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class DeviceCompatibilityService @Inject constructor(
    @ApplicationContext private val context: Context
) {
    
    enum class ARSupport {
        ARCORE_SUPPORTED,
        ARCORE_NOT_SUPPORTED,
        ARCORE_UNKNOWN
    }
    
    enum class CameraSupport {
        CAMERA_SUPPORTED,
        CAMERA_NOT_SUPPORTED
    }
    
    enum class LocationSupport {
        LOCATION_SUPPORTED,
        LOCATION_NOT_SUPPORTED
    }
    
    fun checkARCoreSupport(): ARSupport {
        return try {
            // Check if ARCore is installed
            val packageManager = context.packageManager
            val arcorePackage = "com.google.ar.core"
            
            if (packageManager.getPackageInfo(arcorePackage, 0) != null) {
                // Check if device is supported by ARCore
                if (isARCoreSupportedDevice()) {
                    ARSupport.ARCORE_SUPPORTED
                } else {
                    Log.w("DeviceCompatibility", "ARCore installed but device not supported")
                    ARSupport.ARCORE_NOT_SUPPORTED
                }
            } else {
                Log.w("DeviceCompatibility", "ARCore not installed")
                ARSupport.ARCORE_NOT_SUPPORTED
            }
        } catch (e: PackageManager.NameNotFoundException) {
            Log.w("DeviceCompatibility", "ARCore not installed: ${e.message}")
            ARSupport.ARCORE_NOT_SUPPORTED
        } catch (e: Exception) {
            Log.e("DeviceCompatibility", "Error checking ARCore support: ${e.message}")
            ARSupport.ARCORE_UNKNOWN
        }
    }
    
    private fun isARCoreSupportedDevice(): Boolean {
        // Basic ARCore requirements check
        val minApiLevel = Build.VERSION_CODES.N // API 24 (Android 7.0)
        
        return Build.VERSION.SDK_INT >= minApiLevel &&
               context.packageManager.hasSystemFeature(PackageManager.FEATURE_CAMERA) &&
               context.packageManager.hasSystemFeature(PackageManager.FEATURE_CAMERA_AUTOFOCUS)
    }
    
    fun checkCameraSupport(): CameraSupport {
        return try {
            val packageManager = context.packageManager
            if (packageManager.hasSystemFeature(PackageManager.FEATURE_CAMERA)) {
                CameraSupport.CAMERA_SUPPORTED
            } else {
                CameraSupport.CAMERA_NOT_SUPPORTED
            }
        } catch (e: Exception) {
            Log.e("DeviceCompatibility", "Error checking camera support: ${e.message}")
            CameraSupport.CAMERA_NOT_SUPPORTED
        }
    }
    
    fun checkLocationSupport(): LocationSupport {
        return try {
            val packageManager = context.packageManager
            if (packageManager.hasSystemFeature(PackageManager.FEATURE_LOCATION) ||
                packageManager.hasSystemFeature(PackageManager.FEATURE_LOCATION_GPS)) {
                LocationSupport.LOCATION_SUPPORTED
            } else {
                LocationSupport.LOCATION_NOT_SUPPORTED
            }
        } catch (e: Exception) {
            Log.e("DeviceCompatibility", "Error checking location support: ${e.message}")
            LocationSupport.LOCATION_NOT_SUPPORTED
        }
    }
    
    fun getDeviceInfo(): Map<String, String> {
        return mapOf(
            "manufacturer" to Build.MANUFACTURER,
            "model" to Build.MODEL,
            "android_version" to Build.VERSION.RELEASE,
            "api_level" to Build.VERSION.SDK_INT.toString(),
            "arcore_support" to checkARCoreSupport().name,
            "camera_support" to checkCameraSupport().name,
            "location_support" to checkLocationSupport().name
        )
    }
    
    fun isDeviceCompatible(): Boolean {
        val cameraSupport = checkCameraSupport()
        val locationSupport = checkLocationSupport()
        
        // Device is compatible if it has camera and location support
        // ARCore is optional and will use fallback if not available
        return cameraSupport == CameraSupport.CAMERA_SUPPORTED &&
               locationSupport == LocationSupport.LOCATION_SUPPORTED
    }
    
    fun getRecommendedMode(): String {
        return when (checkARCoreSupport()) {
            ARSupport.ARCORE_SUPPORTED -> "AR_MODE"
            ARSupport.ARCORE_NOT_SUPPORTED -> "CAMERA_MODE"
            ARSupport.ARCORE_UNKNOWN -> "CAMERA_MODE"
        }
    }
} 