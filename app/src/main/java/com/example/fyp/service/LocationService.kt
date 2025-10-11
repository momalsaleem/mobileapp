package com.example.fyp.service

import android.annotation.SuppressLint
import android.content.Context
import android.location.Location
import android.os.Looper
import android.util.Log
import com.google.android.gms.location.*
import kotlinx.coroutines.channels.awaitClose
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.callbackFlow
import kotlinx.coroutines.suspendCancellableCoroutine
import kotlin.coroutines.resume
import kotlin.coroutines.resumeWithException
import android.content.pm.PackageManager
import androidx.core.content.ContextCompat
import android.Manifest

class LocationService(private val context: Context) {
    
    private val fusedLocationClient: FusedLocationProviderClient by lazy {
        LocationServices.getFusedLocationProviderClient(context)
    }
    
    @SuppressLint("MissingPermission")
    suspend fun getCurrentLocation(): Location? {
        return suspendCancellableCoroutine { continuation ->
            fusedLocationClient.lastLocation
                .addOnSuccessListener { location ->
                    if (location != null) {
                        Log.d("LocationService", "Current location: ${location.latitude}, ${location.longitude}")
                        continuation.resume(location)
                    } else {
                        Log.w("LocationService", "Last location is null")
                        continuation.resume(null)
                    }
                }
                .addOnFailureListener { exception ->
                    Log.e("LocationService", "Failed to get current location", exception)
                    continuation.resumeWithException(exception)
                }
        }
    }
    
    @SuppressLint("MissingPermission")
    fun getLocationUpdates(intervalMs: Long = 500): Flow<Location> = callbackFlow {
        // Defensive runtime permission check
        if (ContextCompat.checkSelfPermission(context, Manifest.permission.ACCESS_FINE_LOCATION) != PackageManager.PERMISSION_GRANTED &&
            ContextCompat.checkSelfPermission(context, Manifest.permission.ACCESS_COARSE_LOCATION) != PackageManager.PERMISSION_GRANTED) {
            close(SecurityException("Location permission not granted"))
            return@callbackFlow
        }
        val locationRequest = LocationRequest.Builder(Priority.PRIORITY_HIGH_ACCURACY, intervalMs)
            .setMinUpdateDistanceMeters(0.3f) // Update every 0.3 meters for more precise tracking
            .setMinUpdateIntervalMillis(300) // Minimum 300ms between updates
            .setMaxUpdateDelayMillis(1000) // Maximum 1 second delay
            .build()
        
        val locationCallback = object : LocationCallback() {
            override fun onLocationResult(locationResult: LocationResult) {
                locationResult.lastLocation?.let { location ->
                    Log.d("LocationService", "Location update: ${location.latitude}, ${location.longitude}, accuracy: ${location.accuracy}m")
                    trySend(location)
                }
            }
            
            override fun onLocationAvailability(locationAvailability: LocationAvailability) {
                if (!locationAvailability.isLocationAvailable) {
                    Log.w("LocationService", "Location not available")
                } else {
                    Log.d("LocationService", "Location is available")
                }
            }
        }
        
        fusedLocationClient.requestLocationUpdates(
            locationRequest,
            locationCallback,
            Looper.getMainLooper()
        ).addOnSuccessListener {
            Log.d("LocationService", "Location updates requested successfully with interval: ${intervalMs}ms")
        }.addOnFailureListener { exception ->
            Log.e("LocationService", "Failed to request location updates", exception)
            close(exception)
        }
        
        awaitClose {
            Log.d("LocationService", "Stopping location updates")
            fusedLocationClient.removeLocationUpdates(locationCallback)
        }
    }
    
    fun calculateDistance(lat1: Double, lon1: Double, lat2: Double, lon2: Double): Float {
        val results = FloatArray(1)
        Location.distanceBetween(lat1, lon1, lat2, lon2, results)
        return results[0]
    }
    
    fun calculateBearing(lat1: Double, lon1: Double, lat2: Double, lon2: Double): Float {
        val results = FloatArray(1)
        Location.distanceBetween(lat1, lon1, lat2, lon2, results)
        return results[0]
    }
    
    fun isLocationEnabled(): Boolean {
        return try {
            val locationManager = context.getSystemService(Context.LOCATION_SERVICE) as android.location.LocationManager
            locationManager.isProviderEnabled(android.location.LocationManager.GPS_PROVIDER) ||
            locationManager.isProviderEnabled(android.location.LocationManager.NETWORK_PROVIDER)
        } catch (e: Exception) {
            Log.e("LocationService", "Error checking location enabled", e)
            false
        }
    }
} 