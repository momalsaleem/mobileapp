package com.example.fyp.viewmodel

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.example.fyp.data.entity.LocationPoint
import com.example.fyp.data.entity.KeypointType
import com.example.fyp.data.repository.RouteRepository
import com.example.fyp.service.CameraService
import com.example.fyp.service.FusedPositionService
import com.example.fyp.service.WifiRttService
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.*
import kotlinx.coroutines.launch
import javax.inject.Inject
import android.util.Log
import com.example.fyp.anyplace.AnyplaceClient
import com.example.fyp.anyplace.AnyplaceLocation
import retrofit2.Call
import retrofit2.Callback
import retrofit2.Response
import com.example.fyp.service.MediaPipeService
import com.example.fyp.service.KeypointDetector

@HiltViewModel
class RouteRecordingViewModel @Inject constructor(
    private val routeRepository: RouteRepository,
    private val cameraService: CameraService,
    private val fusedPositionService: FusedPositionService
) : ViewModel() {

    private val _isRecording = MutableStateFlow(false)
    val isRecording: StateFlow<Boolean> = _isRecording

    private val _recordingTime = MutableStateFlow(0)
    val recordingTime: StateFlow<Int> = _recordingTime

    private val _recordedLocations = MutableStateFlow<List<LocationPoint>>(emptyList())
    val recordedLocations: StateFlow<List<LocationPoint>> = _recordedLocations

    private val _currentLocation = MutableStateFlow<LocationPoint?>(null)
    val currentLocation: StateFlow<LocationPoint?> = _currentLocation

    private val _isCameraReady = MutableStateFlow(false)
    val isCameraReady: StateFlow<Boolean> = _isCameraReady

    private val _errorMessage = MutableStateFlow<String?>(null)
    val errorMessage: StateFlow<String?> = _errorMessage

    private val _isSaving = MutableStateFlow(false)
    val isSaving: StateFlow<Boolean> = _isSaving

    private val _keypoints = MutableStateFlow<List<LocationPoint>>(emptyList())
    val keypoints: StateFlow<List<LocationPoint>> = _keypoints

    // MediaPipe integration
    private val _detectedObjects = MutableStateFlow<List<MediaPipeService.DetectedObject>>(emptyList())
    val detectedObjects: StateFlow<List<MediaPipeService.DetectedObject>> = _detectedObjects

    private val _navigationHazards = MutableStateFlow<List<MediaPipeService.NavigationHazard>>(emptyList())
    val navigationHazards: StateFlow<List<MediaPipeService.NavigationHazard>> = _navigationHazards

    private val _navigationGuidance = MutableStateFlow("Path clear ahead")
    val navigationGuidance: StateFlow<String> = _navigationGuidance

    private val _isMediaPipeProcessing = MutableStateFlow(false)
    val isMediaPipeProcessing: StateFlow<Boolean> = _isMediaPipeProcessing

    private var lastBreadcrumbTime = 0L

    // Add KeypointDetector instance
    private val keypointDetector = KeypointDetector()

    init {
        observeLocationUpdates()
        observeMediaPipeResults()
    }

    private fun observeLocationUpdates() {
        viewModelScope.launch {
            fusedPositionService.getFusedPositionFlow()
                .catch { e ->
                    _errorMessage.value = "Location error: ${e.message}"
                }
                .collect { location ->
                    handleNewLocationWithKeypointDetection(location)
                }
        }
    }

    private fun observeMediaPipeResults() {
        viewModelScope.launch {
            cameraService.getDetectedObjects().collect { objects ->
                _detectedObjects.value = objects
            }
        }
        
        viewModelScope.launch {
            cameraService.getNavigationHazards().collect { hazards ->
                _navigationHazards.value = hazards
                updateNavigationGuidance(hazards)
                // Camera-based keypoint detection: if recording and a relevant hazard is detected, mark keypoint
                if (_isRecording.value && hazards.isNotEmpty()) {
                    val currentLoc = _currentLocation.value
                    if (currentLoc != null) {
                        val newKeypoints = hazards.map { hazard ->
                            currentLoc.copy(
                                isKeypoint = true,
                                keypointType = mapHazardTypeToKeypointType(hazard.type),
                                instruction = generateKeypointInstruction(mapHazardTypeToKeypointType(hazard.type))
                            )
                        }
                        // Only add if not already present at this location (avoid duplicates)
                        val existing = _keypoints.value
                        val notAlreadyAdded = newKeypoints.filter { newKp ->
                            existing.none { ex ->
                                fusedPositionService.calculateDistance(
                                    ex.latitude, ex.longitude,
                                    newKp.latitude, newKp.longitude
                                ) < 1.0f && ex.keypointType == newKp.keypointType
                            }
                        }
                        if (notAlreadyAdded.isNotEmpty()) {
                            _keypoints.value = existing + notAlreadyAdded
                        }
                    }
                }
            }
        }
        
        viewModelScope.launch {
            cameraService.isProcessing().collect { isProcessing ->
                _isMediaPipeProcessing.value = isProcessing
            }
        }
    }

    private fun updateNavigationGuidance(hazards: List<MediaPipeService.NavigationHazard>) {
        val guidance = when {
            hazards.isEmpty() -> "Path clear ahead"
            hazards.any { it.type == MediaPipeService.HazardType.PERSON } -> "Person detected ahead"
            hazards.any { it.type == MediaPipeService.HazardType.STAIRS } -> "Stairs detected"
            hazards.any { it.type == MediaPipeService.HazardType.DOOR } -> "Door detected"
            hazards.any { it.type == MediaPipeService.HazardType.OBSTACLE } -> "Obstacle detected ahead"
            hazards.any { it.type == MediaPipeService.HazardType.WET_FLOOR } -> "Wet floor detected"
            hazards.any { it.type == MediaPipeService.HazardType.CONSTRUCTION } -> "Construction area detected"
            else -> "Navigation hazards detected"
        }
        _navigationGuidance.value = guidance
    }

    // Use KeypointDetector for keypoint detection
    private fun handleNewLocationWithKeypointDetection(location: android.location.Location) {
        val currentTime = System.currentTimeMillis()
        val locationPoint = LocationPoint(
            latitude = location.latitude,
            longitude = location.longitude,
            altitude = location.altitude.toFloat(),
            timestamp = currentTime,
            stepNumber = 0,
            instruction = null,
            bearing = location.bearing
        )
        _currentLocation.value = locationPoint
        if (_isRecording.value) {
            // Use Anyplace API for indoor location
            fetchIndoorLocation(location.latitude, location.longitude, "YOUR_BUILDING_ID", "YOUR_FLOOR_NUMBER")
            addLocationToRoute(location, locationPoint)
            // Use KeypointDetector to detect keypoints
            val previousLocation = _recordedLocations.value.lastOrNull()
            val detectedKeypoint = keypointDetector.detectKeypoint(location, previousLocation, _recordedLocations.value)
            if (detectedKeypoint != null) {
                // Only add if not already present at this location (avoid duplicates)
                val existing = _keypoints.value
                val notAlreadyAdded = existing.none { ex ->
                    fusedPositionService.calculateDistance(
                        ex.latitude, ex.longitude,
                        detectedKeypoint.latitude, detectedKeypoint.longitude
                    ) < 1.0f && ex.keypointType == detectedKeypoint.keypointType
                }
                if (notAlreadyAdded) {
                    _keypoints.value = existing + detectedKeypoint
                    Log.d("RouteRecording", "KeypointDetector keypoint added: ${detectedKeypoint.keypointType} at ${detectedKeypoint.latitude}, ${detectedKeypoint.longitude}")
                }
            }
        }
    }

    fun startRecording() {
        _isRecording.value = true
        _recordingTime.value = 0
        _recordedLocations.value = emptyList()
        _keypoints.value = emptyList()
        cameraService.startRecording()
        keypointDetector.reset()
        // Start timer
        viewModelScope.launch {
            while (_isRecording.value) {
                kotlinx.coroutines.delay(1000)
                _recordingTime.value = _recordingTime.value + 1
            }
        }
    }

    fun stopRecording() {
        _isRecording.value = false
        cameraService.stopRecording()
        keypointDetector.reset()
        // No need to call detectKeypointsFromGPS anymore
    }

    private fun addLocationToRoute(location: android.location.Location, locationPoint: LocationPoint) {
        val currentList = _recordedLocations.value.toMutableList()
        
        // Use Clew's approach: combine GPS with visual-inertial data
        // This part is now simplified as we rely on Anyplace API for indoor positioning
        val finalLocationPoint = locationPoint.copy(
            stepNumber = currentList.size + 1,
            instruction = generateClewInstruction(currentList.size + 1, currentList),
            isKeypoint = false // Will be determined by keypoint extraction
        )
        
        currentList.add(finalLocationPoint)
        _recordedLocations.value = currentList
    }

    // Remove or deprecate detectKeypointsFromGPS (no longer used)

    private fun calculateBearingChange(prev: LocationPoint, current: LocationPoint, next: LocationPoint): Float {
        val bearing1 = calculateBearing(prev.latitude, prev.longitude, current.latitude, current.longitude)
        val bearing2 = calculateBearing(current.latitude, current.longitude, next.latitude, next.longitude)
        
        var change = bearing2 - bearing1
        if (change > 180f) change -= 360f
        if (change < -180f) change += 360f
        
        return change
    }

    private fun calculateBearing(lat1: Double, lon1: Double, lat2: Double, lon2: Double): Float {
        val lat1Rad = Math.toRadians(lat1)
        val lat2Rad = Math.toRadians(lat2)
        val deltaLonRad = Math.toRadians(lon2 - lon1)
        
        val y = Math.sin(deltaLonRad) * Math.cos(lat2Rad)
        val x = Math.cos(lat1Rad) * Math.sin(lat2Rad) - Math.sin(lat1Rad) * Math.cos(lat2Rad) * Math.cos(deltaLonRad)
        
        val bearing = Math.toDegrees(Math.atan2(y, x))
        return ((bearing + 360) % 360).toFloat()
    }

    private fun generateClewInstruction(stepNumber: Int, previousLocations: List<LocationPoint>): String {
        return when (stepNumber) {
            1 -> "Start here"
            else -> "Continue following the path"
        }
    }

    private fun generateKeypointInstruction(keypointType: KeypointType): String {
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

    fun saveRoute(name: String, description: String, startLocation: String, endLocation: String) {
        viewModelScope.launch {
            try {
                _isSaving.value = true
                
                // Allow short routes: minimum 2 breadcrumbs
                if (_recordedLocations.value.size < 2) {
                    _errorMessage.value = "Not enough locations recorded. Please record at least two points."
                    _isSaving.value = false
                    return@launch
                }
                
                // Merge keypoints with recorded locations
                val locationsWithKeypoints = mergeKeypointsWithLocations()
                
                // Allow short routes: at least 1 keypoint
                if (locationsWithKeypoints.none { it.isKeypoint }) {
                    _errorMessage.value = "No keypoints detected. Please record a route with at least one turn or change."
                    _isSaving.value = false
                    return@launch
                }
                
                val routeId = routeRepository.createRoute(
                    name = name,
                    description = description,
                    startLocation = startLocation,
                    endLocation = endLocation,
                    locations = locationsWithKeypoints
                )
                
                _isSaving.value = false
                Log.d("RouteRecording", "Route saved successfully with ${locationsWithKeypoints.size} locations and ${locationsWithKeypoints.count { it.isKeypoint }} keypoints")
                
            } catch (e: Exception) {
                _isSaving.value = false
                _errorMessage.value = "Failed to save route: ${e.message}"
            }
        }
    }
    fun resetRouteSaved() { }
    
    private fun mergeKeypointsWithLocations(): List<LocationPoint> {
        val locations = _recordedLocations.value.toMutableList()
        val keypoints = _keypoints.value
        
        // Mark start and end points as keypoints
        if (locations.isNotEmpty()) {
            locations[0] = locations[0].copy(
                isKeypoint = true,
                keypointType = KeypointType.NONE,
                instruction = "Start here"
            )
            locations[locations.size - 1] = locations[locations.size - 1].copy(
                isKeypoint = true,
                keypointType = KeypointType.NONE,
                instruction = "You have arrived"
            )
        }
        
        // Add detected keypoints to the route
        for (keypoint in keypoints) {
            // Find the closest location point and mark it as a keypoint
            val closestIndex = findClosestLocationIndex(keypoint, locations)
            if (closestIndex >= 0) {
                locations[closestIndex] = locations[closestIndex].copy(
                    isKeypoint = true,
                    keypointType = keypoint.keypointType,
                    instruction = keypoint.instruction
                )
            }
        }
        
        return locations
    }
    
    private fun findClosestLocationIndex(keypoint: LocationPoint, locations: List<LocationPoint>): Int {
        if (locations.isEmpty()) return -1
        
        var closestIndex = 0
        var minDistance = Float.MAX_VALUE
        
        for (i in locations.indices) {
            val distance = fusedPositionService.calculateDistance(
                keypoint.latitude, keypoint.longitude,
                locations[i].latitude, locations[i].longitude
            )
            if (distance < minDistance) {
                minDistance = distance
                closestIndex = i
            }
        }
        
        return closestIndex
    }

    fun clearError() {
        _errorMessage.value = null
    }

    fun startCamera(lifecycleOwner: androidx.lifecycle.LifecycleOwner, previewView: androidx.camera.view.PreviewView) {
        cameraService.startCamera(lifecycleOwner, previewView) {
            _isCameraReady.value = true
            // Optionally call Anyplace API when camera starts
            _currentLocation.value?.let { loc ->
                fetchIndoorLocation(loc.latitude, loc.longitude, "YOUR_BUILDING_ID", "YOUR_FLOOR_NUMBER")
            }
        }
        
        // Observe camera errors
        viewModelScope.launch {
            cameraService.errorMessage.collect { error ->
                if (error != null) {
                    _errorMessage.value = error
                    _isCameraReady.value = false
                }
            }
        }
    }

    fun getRouteStats(): RouteStats {
        val locations = _recordedLocations.value
        val keypoints = _keypoints.value
        val duration = _recordingTime.value
        val distance = calculateTotalDistance(locations)
        
        return RouteStats(
            duration = duration,
            distance = distance,
            steps = locations.size,
            keypoints = keypoints.size,
            breadcrumbs = 0, // No breadcrumbs in this simplified version
            averageSpeed = if (duration > 0) distance / duration else 0f
        )
    }

    private fun calculateTotalDistance(locations: List<LocationPoint>): Float {
        if (locations.size < 2) return 0f
        var totalDistance = 0f
        for (i in 0 until locations.size - 1) {
            totalDistance += fusedPositionService.calculateDistance(
                locations[i].latitude,
                locations[i].longitude,
                locations[i + 1].latitude,
                locations[i + 1].longitude
            )
        }
        return totalDistance
    }

    fun fetchIndoorLocation(lat: Double, lon: Double, buildingId: String, floor: String) {
        val call = AnyplaceClient.api.getIndoorLocation(lat, lon, buildingId, floor)
        call.enqueue(object : Callback<AnyplaceLocation> {
            override fun onResponse(call: Call<AnyplaceLocation>, response: Response<AnyplaceLocation>) {
                if (response.isSuccessful) {
                    val location = response.body()
                    Log.d("Anyplace", "Indoor location: $location")
                    // TODO: Use the location for navigation or recording
                } else {
                    Log.e("Anyplace", "API error: ${response.errorBody()?.string()}")
                }
            }

            override fun onFailure(call: Call<AnyplaceLocation>, t: Throwable) {
                Log.e("Anyplace", "Network error: ${t.message}")
            }
        })
    }

    override fun onCleared() {
        super.onCleared()
        cameraService.shutdown()
    }

    // Add this function to map hazard type to KeypointType
    private fun mapHazardTypeToKeypointType(hazardType: MediaPipeService.HazardType): KeypointType {
        return when (hazardType) {
            MediaPipeService.HazardType.STAIRS -> KeypointType.STAIRS_UP // or STAIRS_DOWN if you can distinguish
            MediaPipeService.HazardType.DOOR -> KeypointType.DOOR
            MediaPipeService.HazardType.PERSON -> KeypointType.LANDMARK // treat person as a landmark
            MediaPipeService.HazardType.OBSTACLE -> KeypointType.LANDMARK // treat obstacle as a landmark
            MediaPipeService.HazardType.WET_FLOOR -> KeypointType.LANDMARK
            MediaPipeService.HazardType.CONSTRUCTION -> KeypointType.LANDMARK
            MediaPipeService.HazardType.VEHICLE -> KeypointType.LANDMARK
        }
    }
}

data class RouteStats(
    val duration: Int,
    val distance: Float,
    val steps: Int,
    val keypoints: Int,
    val breadcrumbs: Int,
    val averageSpeed: Float
) 