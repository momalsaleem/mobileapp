package com.example.fyp.viewmodel

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.example.fyp.data.entity.RouteEntity
import com.example.fyp.data.repository.RouteRepository
import com.example.fyp.service.FusedPositionService
import com.example.fyp.service.ClewNavigationService
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

@HiltViewModel
class RouteNavigationViewModel @Inject constructor(
    private val routeRepository: RouteRepository,
    private val fusedPositionService: FusedPositionService,
    private val clewNavigationService: ClewNavigationService
) : ViewModel() {

    private val _routes = MutableStateFlow<List<RouteEntity>>(emptyList())
    val routes: StateFlow<List<RouteEntity>> = _routes

    private val _selectedRoute = MutableStateFlow<RouteEntity?>(null)
    val selectedRoute: StateFlow<RouteEntity?> = _selectedRoute

    private val _isNavigating = MutableStateFlow(false)
    val isNavigating: StateFlow<Boolean> = _isNavigating

    private val _currentLocation = MutableStateFlow<android.location.Location?>(null)
    val currentLocation: StateFlow<android.location.Location?> = _currentLocation

    private val _navigationProgress = MutableStateFlow(0f)
    val navigationProgress: StateFlow<Float> = _navigationProgress

    private val _currentInstruction = MutableStateFlow("")
    val currentInstruction: StateFlow<String> = _currentInstruction

    private val _distanceToNext = MutableStateFlow(0f)
    val distanceToNext: StateFlow<Float> = _distanceToNext

    private val _errorMessage = MutableStateFlow<String?>(null)
    val errorMessage: StateFlow<String?> = _errorMessage

    private val _nextKeypoint = MutableStateFlow<com.example.fyp.data.entity.LocationPoint?>(null)
    val nextKeypoint: StateFlow<com.example.fyp.data.entity.LocationPoint?> = _nextKeypoint

    // Clew-specific navigation states
    private val _navigationStatus = MutableStateFlow(ClewNavigationService.NavigationStatus.IDLE)
    val navigationStatus: StateFlow<ClewNavigationService.NavigationStatus> = _navigationStatus

    private val _currentKeypoint = MutableStateFlow<com.example.fyp.data.entity.LocationPoint?>(null)
    val currentKeypoint: StateFlow<com.example.fyp.data.entity.LocationPoint?> = _currentKeypoint

    init {
        loadRoutes()
        observeClewNavigationService()
        observeLocationUpdates()
    }

    private fun loadRoutes() {
        viewModelScope.launch {
            routeRepository.getAllRoutes()
                .catch { e ->
                    _errorMessage.value = "Failed to load routes: ${e.message}"
                }
                .collect { routes ->
                    _routes.value = routes
                }
        }
    }

    private fun observeClewNavigationService() {
        viewModelScope.launch {
            combine(
                clewNavigationService.isNavigating,
                clewNavigationService.currentInstruction,
                clewNavigationService.navigationProgress,
                clewNavigationService.distanceToNext,
                clewNavigationService.nextKeypoint,
                clewNavigationService.currentKeypoint,
                clewNavigationService.navigationStatus
            ) { values: Array<Any?> ->
                val isNav = values[0] as Boolean
                val instruction = values[1] as String
                val progress = values[2] as Float
                val distance = values[3] as Float
                val nextKey = values[4] as com.example.fyp.data.entity.LocationPoint?
                val currentKey = values[5] as com.example.fyp.data.entity.LocationPoint?
                val status = values[6] as ClewNavigationService.NavigationStatus
                _isNavigating.value = isNav
                _currentInstruction.value = instruction
                _navigationProgress.value = progress
                _distanceToNext.value = distance
                _nextKeypoint.value = nextKey
                _currentKeypoint.value = currentKey
                _navigationStatus.value = status
            }.collect()
        }
    }

    private fun observeLocationUpdates() {
        viewModelScope.launch {
            fusedPositionService.getFusedPositionFlow()
                .catch { e ->
                    _errorMessage.value = "Location error: ${e.message}"
                }
                .collect { location ->
                    _currentLocation.value = location
                    // Call Anyplace API for indoor location
                    // TODO: Replace with actual buildingId and floor from user selection or context
                    fetchIndoorLocation(location.latitude, location.longitude, "YOUR_BUILDING_ID", "YOUR_FLOOR_NUMBER")
                    // Update Clew navigation service with current position
                    if (_isNavigating.value) {
                        clewNavigationService.updatePosition(
                            userLat = location.latitude,
                            userLon = location.longitude,
                            userAlt = location.altitude.toFloat()
                        )
                    }
                }
        }
    }

    fun fetchIndoorLocation(lat: Double, lon: Double, buildingId: String, floor: String) {
        val call = AnyplaceClient.api.getIndoorLocation(lat, lon, buildingId, floor)
        call.enqueue(object : Callback<AnyplaceLocation> {
            override fun onResponse(call: Call<AnyplaceLocation>, response: Response<AnyplaceLocation>) {
                if (response.isSuccessful) {
                    val location = response.body()
                    Log.d("Anyplace", "Indoor location: $location")
                    // TODO: Use the location for navigation or UI
                } else {
                    Log.e("Anyplace", "API error: ${response.errorBody()?.string()}")
                }
            }

            override fun onFailure(call: Call<AnyplaceLocation>, t: Throwable) {
                Log.e("Anyplace", "Network error: ${t.message}")
            }
        })
    }

    fun selectRoute(route: RouteEntity?) {
        _selectedRoute.value = route
    }

    fun startNavigation() {
        val selectedRoute = _selectedRoute.value
        if (selectedRoute == null) {
            _errorMessage.value = "No route selected"
            return
        }

        if (selectedRoute.locations.isEmpty()) {
            _errorMessage.value = "Selected route has no navigation points"
            return
        }

        // Check if route has keypoints (Clew requirement)
        val keypoints = selectedRoute.locations.filter { it.isKeypoint }
        if (keypoints.isEmpty()) {
            _errorMessage.value = "Selected route has no keypoints for navigation"
            return
        }

        try {
            clewNavigationService.startNavigation(selectedRoute)
            Log.d("RouteNavigation", "Started Clew navigation for route: ${selectedRoute.name}")
        } catch (e: Exception) {
            _errorMessage.value = "Failed to start navigation: ${e.message}"
        }
    }

    fun stopNavigation() {
        try {
            clewNavigationService.stopNavigation()
            Log.d("RouteNavigation", "Stopped Clew navigation")
        } catch (e: Exception) {
            _errorMessage.value = "Failed to stop navigation: ${e.message}"
        }
    }

    fun pauseNavigation() {
        // Clew doesn't have pause, but we can implement it
        _currentInstruction.value = "Navigation paused"
    }

    fun resumeNavigation() {
        // Resume navigation
        _currentInstruction.value = "Navigation resumed"
    }

    fun getRouteById(routeId: Long) {
        viewModelScope.launch {
            try {
                val route = routeRepository.getRouteById(routeId)
                _selectedRoute.value = route
            } catch (e: Exception) {
                _errorMessage.value = "Failed to load route: ${e.message}"
            }
        }
    }

    fun clearError() {
        _errorMessage.value = null
    }

    fun getEstimatedTimeRemaining(): Int {
        val selectedRoute = _selectedRoute.value ?: return 0
        val progress = _navigationProgress.value
        val remainingProgress = 100f - progress
        return ((remainingProgress / 100f) * selectedRoute.duration).toInt()
    }

    fun getCurrentStep(): Int {
        return clewNavigationService.getCurrentKeypointIndex()
    }

    fun getTotalSteps(): Int {
        return clewNavigationService.getTotalKeypoints()
    }

    fun isNearDestination(): Boolean {
        val currentLoc = _currentLocation.value
        val selectedRoute = _selectedRoute.value
        
        if (currentLoc == null || selectedRoute == null) return false
        
        val destination = selectedRoute.locations.lastOrNull() ?: return false
        val distance = fusedPositionService.calculateDistance(
            currentLoc.latitude, currentLoc.longitude,
            destination.latitude, destination.longitude
        )
        return distance <= 5f
    }

    fun isNavigationComplete(): Boolean {
        return clewNavigationService.isNavigationComplete()
    }

    fun getNavigationStatus(): ClewNavigationService.NavigationStatus {
        return clewNavigationService.getNavigationStatus()
    }

    fun getCurrentKeypointIndex(): Int {
        return clewNavigationService.getCurrentKeypointIndex()
    }

    fun getTotalKeypoints(): Int {
        return clewNavigationService.getTotalKeypoints()
    }

    // Clew-style navigation helper functions
    fun getCurrentKeypointType(): String {
        val currentKey = _currentKeypoint.value
        return currentKey?.keypointType?.name ?: "NONE"
    }

    fun getNextKeypointType(): String {
        val nextKey = _nextKeypoint.value
        return nextKey?.keypointType?.name ?: "NONE"
    }

    fun getDistanceToNextFormatted(): String {
        val distance = _distanceToNext.value
        return when {
            distance < 1f -> "${(distance * 100).toInt()} cm"
            distance < 10f -> "${distance.toInt()} meters"
            else -> "${(distance / 10).toInt() * 10} meters"
        }
    }

    fun getNavigationProgressPercentage(): Int {
        return _navigationProgress.value.toInt()
    }

    fun isApproachingKeypoint(): Boolean {
        return _navigationStatus.value == ClewNavigationService.NavigationStatus.APPROACHING
    }

    fun isAtKeypoint(): Boolean {
        return _navigationStatus.value == ClewNavigationService.NavigationStatus.MOVING_TO_NEXT
    }

    fun isMoving(): Boolean {
        return _navigationStatus.value == ClewNavigationService.NavigationStatus.MOVING
    }

    fun hasArrived(): Boolean {
        return _navigationStatus.value == ClewNavigationService.NavigationStatus.ARRIVED
    }

    override fun onCleared() {
        super.onCleared()
        clewNavigationService.shutdown()
    }
} 