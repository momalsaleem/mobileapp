package com.example.fyp.service

import android.location.Location
import android.util.Log
import com.example.fyp.data.entity.LocationPoint
import com.example.fyp.data.entity.KeypointType
import kotlin.math.abs
import kotlin.math.atan2
import kotlin.math.cos
import kotlin.math.sin

class KeypointDetector {
    
    companion object {
        private const val TAG = "KeypointDetector"
        
        // Adjusted thresholds for better indoor navigation (more sensitive than before)
        private const val TURN_THRESHOLD = 20f // degrees - reduced from 30f for more sensitive turn detection
        private const val STAIRS_THRESHOLD = 1.0f // meters - reduced from 1.5f for more sensitive stair detection
        private const val MIN_DISTANCE_BETWEEN_KEYPOINTS = 1.5f // meters - reduced from 2f for more frequent keypoints
        private const val BEARING_SMOOTHING_WINDOW = 2 // reduced from 3 for more responsive detection
        private const val SLOW_MOVEMENT_THRESHOLD = 0.3f // m/s - for door/landmark detection
    }
    
    private var lastKeypointLocation: LocationPoint? = null
    private val bearingHistory = mutableListOf<Float>()
    
    /**
     * Detects if a new location point should be marked as a keypoint
     * Based on Clew's keypoint detection logic
     */
    fun detectKeypoint(
        currentLocation: Location,
        previousLocation: LocationPoint?,
        allLocations: List<LocationPoint>
    ): LocationPoint? {
        if (previousLocation == null) {
            // First point is always a keypoint (start point)
            return createLocationPoint(currentLocation, 1, true, KeypointType.NONE, "Start here")
        }
        
        val currentPoint = createLocationPoint(currentLocation, allLocations.size + 1, false, KeypointType.NONE)
        
        // Check if we're too close to the last keypoint
        if (lastKeypointLocation != null) {
            val distanceToLastKeypoint = calculateDistance(
                currentPoint.latitude, currentPoint.longitude,
                lastKeypointLocation!!.latitude, lastKeypointLocation!!.longitude
            )
            if (distanceToLastKeypoint < MIN_DISTANCE_BETWEEN_KEYPOINTS) {
                return null
            }
        }
        
        // Detect keypoint type
        val keypointType = detectKeypointType(currentPoint, previousLocation, allLocations)
        
        if (keypointType != KeypointType.NONE) {
            val instruction = generateKeypointInstruction(keypointType, currentPoint, previousLocation)
            val keypoint = currentPoint.copy(
                isKeypoint = true,
                keypointType = keypointType,
                instruction = instruction
            )
            lastKeypointLocation = keypoint
            Log.d(TAG, "Keypoint detected: $keypointType at ${keypoint.latitude}, ${keypoint.longitude}")
            return keypoint
        }
        
        return null
    }
    
    private fun detectKeypointType(
        current: LocationPoint,
        previous: LocationPoint,
        allLocations: List<LocationPoint>
    ): KeypointType {
        // Detect turns based on bearing change (more sensitive)
        val bearingChange = abs(current.bearing - previous.bearing)
        if (bearingChange > TURN_THRESHOLD) {
            return when {
                bearingChange > 150f -> KeypointType.TURN_AROUND
                current.bearing > previous.bearing -> KeypointType.TURN_RIGHT
                else -> KeypointType.TURN_LEFT
            }
        }
        
        // Detect stairs based on elevation change (more sensitive)
        val elevationChange = current.altitude - previous.altitude
        if (abs(elevationChange) > STAIRS_THRESHOLD) {
            return if (elevationChange > 0) KeypointType.STAIRS_UP else KeypointType.STAIRS_DOWN
        }
        
        // Detect doors or landmarks based on speed changes (more sensitive)
        if (allLocations.size >= 2) {
            val recentLocations = allLocations.takeLast(2)
            val averageSpeed = calculateAverageSpeed(recentLocations)
            if (averageSpeed < SLOW_MOVEMENT_THRESHOLD) { // Very slow movement might indicate a door or landmark
                return KeypointType.DOOR
            }
        }
        
        return KeypointType.NONE
    }
    
    private fun generateKeypointInstruction(
        keypointType: KeypointType,
        current: LocationPoint,
        previous: LocationPoint
    ): String {
        return when (keypointType) {
            KeypointType.TURN_LEFT -> "Turn left"
            KeypointType.TURN_RIGHT -> "Turn right"
            KeypointType.TURN_AROUND -> "Turn around"
            KeypointType.STAIRS_UP -> "Go up the stairs"
            KeypointType.STAIRS_DOWN -> "Go down the stairs"
            KeypointType.ELEVATOR -> "Take the elevator"
            KeypointType.DOOR -> "Go through the door"
            KeypointType.LANDMARK -> "Continue past the landmark"
            KeypointType.NONE -> "Continue straight"
        }
    }
    
    private fun createLocationPoint(
        location: Location,
        stepNumber: Int,
        isKeypoint: Boolean,
        keypointType: KeypointType,
        instruction: String? = null
    ): LocationPoint {
        val bearing = location.bearing
        updateBearingHistory(bearing)
        
        return LocationPoint(
            latitude = location.latitude,
            longitude = location.longitude,
            altitude = location.altitude.toFloat(),
            timestamp = System.currentTimeMillis(),
            stepNumber = stepNumber,
            instruction = instruction,
            bearing = getSmoothedBearing(),
            isKeypoint = isKeypoint,
            keypointType = keypointType
        )
    }
    
    private fun updateBearingHistory(bearing: Float) {
        bearingHistory.add(bearing)
        if (bearingHistory.size > BEARING_SMOOTHING_WINDOW) {
            bearingHistory.removeAt(0)
        }
    }
    
    private fun getSmoothedBearing(): Float {
        if (bearingHistory.isEmpty()) return 0f
        
        // Calculate average bearing, handling wraparound (0-360 degrees)
        val sinSum = bearingHistory.sumOf { sin(Math.toRadians(it.toDouble())) }
        val cosSum = bearingHistory.sumOf { cos(Math.toRadians(it.toDouble())) }
        val avgBearing = Math.toDegrees(atan2(sinSum, cosSum))
        return ((avgBearing + 360) % 360).toFloat()
    }
    
    private fun calculateDistance(lat1: Double, lon1: Double, lat2: Double, lon2: Double): Float {
        val results = FloatArray(1)
        Location.distanceBetween(lat1, lon1, lat2, lon2, results)
        return results[0]
    }
    
    private fun calculateAverageSpeed(locations: List<LocationPoint>): Float {
        if (locations.size < 2) return 0f
        
        var totalDistance = 0f
        var totalTime = 0L
        
        for (i in 0 until locations.size - 1) {
            val distance = calculateDistance(
                locations[i].latitude, locations[i].longitude,
                locations[i + 1].latitude, locations[i + 1].longitude
            )
            val time = locations[i + 1].timestamp - locations[i].timestamp
            
            totalDistance += distance
            totalTime += time
        }
        
        return if (totalTime > 0) totalDistance / (totalTime / 1000f) else 0f
    }
    
    fun reset() {
        lastKeypointLocation = null
        bearingHistory.clear()
    }
} 