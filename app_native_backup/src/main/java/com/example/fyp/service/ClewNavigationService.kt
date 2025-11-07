package com.example.fyp.service

import android.content.Context
import android.speech.tts.TextToSpeech
import android.util.Log
import com.example.fyp.data.entity.RouteEntity
import com.example.fyp.data.entity.LocationPoint
import com.example.fyp.data.entity.KeypointType
import dagger.hilt.android.qualifiers.ApplicationContext
import javax.inject.Inject
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import java.util.*

/**
 * Clew-style Navigation Service
 * Implements the exact navigation behavior from Clew app
 */
class ClewNavigationService @Inject constructor(
    @ApplicationContext private val context: Context
) {
    
    companion object {
        private const val TAG = "ClewNavigationService"
        private const val APPROACH_DISTANCE = 2f // meters - when to start giving approach instructions
        private const val ARRIVAL_DISTANCE = 0.5f // meters - when to give arrival instructions
        private const val KEYPOINT_REACHED_DISTANCE = 1f // meters - when to mark keypoint as reached
    }
    
    private var textToSpeech: TextToSpeech? = null
    private var currentRoute: RouteEntity? = null
    private var isTTSReady = false
    
    // Clew-style navigation state
    private var currentKeypointIndex = 0
    private var reachedKeypoints = mutableSetOf<Int>()
    private var lastSpokenKeypoint: Int? = null
    private var isApproachingKeypoint = false
    
    private val _isNavigating = MutableStateFlow(false)
    val isNavigating: StateFlow<Boolean> = _isNavigating
    
    private val _currentKeypoint = MutableStateFlow<LocationPoint?>(null)
    val currentKeypoint: StateFlow<LocationPoint?> = _currentKeypoint
    
    private val _nextKeypoint = MutableStateFlow<LocationPoint?>(null)
    val nextKeypoint: StateFlow<LocationPoint?> = _nextKeypoint
    
    private val _navigationProgress = MutableStateFlow(0f)
    val navigationProgress: StateFlow<Float> = _navigationProgress
    
    private val _distanceToNext = MutableStateFlow(0f)
    val distanceToNext: StateFlow<Float> = _distanceToNext
    
    private val _currentInstruction = MutableStateFlow("")
    val currentInstruction: StateFlow<String> = _currentInstruction
    
    private val _navigationStatus = MutableStateFlow(NavigationStatus.IDLE)
    val navigationStatus: StateFlow<NavigationStatus> = _navigationStatus
    
    init {
        initializeTTS()
    }
    
    private fun initializeTTS() {
        textToSpeech = TextToSpeech(context) { status ->
            if (status == TextToSpeech.SUCCESS) {
                val result = textToSpeech?.setLanguage(Locale.US)
                if (result == TextToSpeech.LANG_MISSING_DATA || result == TextToSpeech.LANG_NOT_SUPPORTED) {
                    Log.e(TAG, "TTS language not supported")
                } else {
                    isTTSReady = true
                    textToSpeech?.setSpeechRate(0.8f) // Slower speech rate like Clew
                    Log.d(TAG, "TTS initialized successfully")
                }
            } else {
                Log.e(TAG, "TTS initialization failed")
            }
        }
    }
    
    /**
     * Start Clew-style navigation
     */
    fun startNavigation(route: RouteEntity) {
        if (route.locations.isEmpty()) {
            Log.e(TAG, "Route has no locations")
            return
        }
        
        val keypoints = route.locations.filter { it.isKeypoint }
        if (keypoints.isEmpty()) {
            Log.e(TAG, "Route has no keypoints")
            return
        }
        
        currentRoute = route
        currentKeypointIndex = 0
        reachedKeypoints.clear()
        lastSpokenKeypoint = null
        isApproachingKeypoint = false
        
        _isNavigating.value = true
        _navigationStatus.value = NavigationStatus.STARTING
        _currentKeypoint.value = keypoints.first()
        _nextKeypoint.value = if (keypoints.size > 1) keypoints[1] else null
        
        // Clew-style start announcement
        speak("Starting navigation. Follow the path to your destination.")
        Log.d(TAG, "Clew navigation started with ${keypoints.size} keypoints")
    }
    
    /**
     * Stop navigation
     */
    fun stopNavigation() {
        currentRoute = null
        currentKeypointIndex = 0
        reachedKeypoints.clear()
        lastSpokenKeypoint = null
        isApproachingKeypoint = false
        
        _isNavigating.value = false
        _navigationStatus.value = NavigationStatus.IDLE
        _currentKeypoint.value = null
        _nextKeypoint.value = null
        _navigationProgress.value = 0f
        _distanceToNext.value = 0f
        _currentInstruction.value = ""
        
        speak("Navigation stopped")
        Log.d(TAG, "Clew navigation stopped")
    }
    
    /**
     * Update user position and provide Clew-style navigation guidance
     */
    fun updatePosition(userLat: Double, userLon: Double, userAlt: Float = 0f) {
        if (!_isNavigating.value || currentRoute == null) return
        
        val keypoints = currentRoute!!.locations.filter { it.isKeypoint }
        if (keypoints.isEmpty()) return
        
        // Find current target keypoint
        val targetKeypoint = keypoints.getOrNull(currentKeypointIndex) ?: return
        
        // Calculate distance to target keypoint
        val distance = calculateDistance(userLat, userLon, targetKeypoint.latitude, targetKeypoint.longitude)
        _distanceToNext.value = distance
        
        // Update progress
        val progress = (currentKeypointIndex.toFloat() / keypoints.size) * 100
        _navigationProgress.value = progress.coerceIn(0f, 100f)
        
        // Clew-style navigation logic
        val currentType = targetKeypoint.keypointType
        val nextType = keypoints.getOrNull(currentKeypointIndex + 1)?.keypointType
        Log.d(TAG, "Navigation: currentKeypointType=$currentType, nextKeypointType=$nextType, distance=$distance")
        when {
            // Arrived at keypoint
            distance <= ARRIVAL_DISTANCE && !reachedKeypoints.contains(currentKeypointIndex) -> {
                handleKeypointArrival(targetKeypoint, currentKeypointIndex)
            }
            
            // Approaching keypoint
            distance <= APPROACH_DISTANCE && !isApproachingKeypoint -> {
                handleKeypointApproach(targetKeypoint, distance)
            }
            
            // Moving between keypoints
            else -> {
                val instruction = handleBetweenKeypoints(targetKeypoint, distance)
                _currentInstruction.value = instruction
                Log.d(TAG, "Instruction: $instruction")
            }
        }
    }
    
    /**
     * Handle arrival at a keypoint (Clew's arrival behavior)
     */
    private fun handleKeypointArrival(keypoint: LocationPoint, keypointIndex: Int) {
        reachedKeypoints.add(keypointIndex)
        isApproachingKeypoint = false
        
        // Give arrival instruction
        val instruction = generateArrivalInstruction(keypoint)
        _currentInstruction.value = instruction
        speak(instruction)
        
        Log.d(TAG, "Arrived at keypoint ${keypointIndex}: ${keypoint.keypointType}")
        
        // Move to next keypoint
        val keypoints = currentRoute!!.locations.filter { it.isKeypoint }
        if (currentKeypointIndex < keypoints.size - 1) {
            currentKeypointIndex++
            _currentKeypoint.value = keypoints[currentKeypointIndex]
            _nextKeypoint.value = keypoints.getOrNull(currentKeypointIndex + 1)
            
            // Give next instruction
            val nextInstruction = generateNextInstruction(keypoints[currentKeypointIndex])
            speak(nextInstruction)
            
            _navigationStatus.value = NavigationStatus.MOVING_TO_NEXT
        } else {
            // Reached destination
            _navigationStatus.value = NavigationStatus.ARRIVED
            _currentInstruction.value = "You have arrived at your destination"
            speak("You have arrived at your destination")
            Log.d(TAG, "Navigation completed - arrived at destination")
        }
    }
    
    /**
     * Handle approaching a keypoint (Clew's approach behavior)
     */
    private fun handleKeypointApproach(keypoint: LocationPoint, distance: Float) {
        isApproachingKeypoint = true
        lastSpokenKeypoint = currentKeypointIndex
        
        val instruction = generateApproachInstruction(keypoint, distance)
        _currentInstruction.value = instruction
        speak(instruction)
        
        _navigationStatus.value = NavigationStatus.APPROACHING
        Log.d(TAG, "Approaching keypoint ${currentKeypointIndex}: ${keypoint.keypointType}")
    }
    
    /**
     * Handle movement between keypoints
     */
    private fun handleBetweenKeypoints(keypoint: LocationPoint, distance: Float): String {
        _navigationStatus.value = NavigationStatus.MOVING
        return "Continue toward the next keypoint"
    }
    
    /**
     * Generate arrival instruction (Clew's arrival instructions)
     */
    private fun generateArrivalInstruction(keypoint: LocationPoint): String {
        return when (keypoint.keypointType) {
            KeypointType.TURN_LEFT -> "Turn left now"
            KeypointType.TURN_RIGHT -> "Turn right now"
            KeypointType.TURN_AROUND -> "Turn around now"
            KeypointType.STAIRS_UP -> "Go up the stairs"
            KeypointType.STAIRS_DOWN -> "Go down the stairs"
            KeypointType.ELEVATOR -> "Take the elevator"
            KeypointType.DOOR -> "Go through the door"
            KeypointType.LANDMARK -> "Continue past the landmark"
            KeypointType.NONE -> "Continue straight"
        }
    }
    
    /**
     * Generate approach instruction (Clew's approach warnings)
     */
    private fun generateApproachInstruction(keypoint: LocationPoint, distance: Float): String {
        val distanceText = when {
            distance < 1f -> "very close"
            distance < 1.5f -> "close"
            else -> "approaching"
        }
        
        return when (keypoint.keypointType) {
            KeypointType.TURN_LEFT -> "Get ready to turn left"
            KeypointType.TURN_RIGHT -> "Get ready to turn right"
            KeypointType.TURN_AROUND -> "Get ready to turn around"
            KeypointType.STAIRS_UP -> "Approaching stairs going up"
            KeypointType.STAIRS_DOWN -> "Approaching stairs going down"
            KeypointType.ELEVATOR -> "Approaching elevator"
            KeypointType.DOOR -> "Approaching door"
            KeypointType.LANDMARK -> "Approaching landmark"
            KeypointType.NONE -> "Continue straight"
        }
    }
    
    /**
     * Generate next instruction after reaching a keypoint
     */
    private fun generateNextInstruction(keypoint: LocationPoint): String {
        return when (keypoint.keypointType) {
            KeypointType.TURN_LEFT -> "Now turn left and continue"
            KeypointType.TURN_RIGHT -> "Now turn right and continue"
            KeypointType.TURN_AROUND -> "Now turn around and continue"
            KeypointType.STAIRS_UP -> "Now go up the stairs"
            KeypointType.STAIRS_DOWN -> "Now go down the stairs"
            KeypointType.ELEVATOR -> "Now take the elevator"
            KeypointType.DOOR -> "Now go through the door"
            KeypointType.LANDMARK -> "Now continue past the landmark"
            KeypointType.NONE -> "Continue straight"
        }
    }
    
    /**
     * Speak text using TTS (Clew's speech behavior)
     */
    private fun speak(text: String) {
        if (isTTSReady && textToSpeech != null) {
            textToSpeech?.speak(text, TextToSpeech.QUEUE_FLUSH, null, null)
            Log.d(TAG, "Speaking: $text")
        } else {
            Log.w(TAG, "TTS not ready, cannot speak: $text")
        }
    }
    
    /**
     * Calculate distance between two points
     */
    private fun calculateDistance(lat1: Double, lon1: Double, lat2: Double, lon2: Double): Float {
        val results = FloatArray(1)
        android.location.Location.distanceBetween(lat1, lon1, lat2, lon2, results)
        return results[0]
    }
    
    /**
     * Get current navigation status
     */
    fun getNavigationStatus(): NavigationStatus = _navigationStatus.value
    
    /**
     * Get current keypoint index
     */
    fun getCurrentKeypointIndex(): Int = currentKeypointIndex
    
    /**
     * Get total keypoints count
     */
    fun getTotalKeypoints(): Int {
        return currentRoute?.locations?.count { it.isKeypoint } ?: 0
    }
    
    /**
     * Check if navigation is complete
     */
    fun isNavigationComplete(): Boolean {
        return _navigationStatus.value == NavigationStatus.ARRIVED
    }
    
    /**
     * Cleanup resources
     */
    fun shutdown() {
        textToSpeech?.stop()
        textToSpeech?.shutdown()
        textToSpeech = null
        isTTSReady = false
        Log.d(TAG, "Clew navigation service shutdown")
    }
    
    /**
     * Navigation status enum (Clew's navigation states)
     */
    enum class NavigationStatus {
        IDLE,
        STARTING,
        MOVING,
        APPROACHING,
        MOVING_TO_NEXT,
        ARRIVED
    }
} 