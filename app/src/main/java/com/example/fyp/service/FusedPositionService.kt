package com.example.fyp.service

import android.content.Context
import android.location.Location
import android.os.Build
import android.util.Log
import dagger.hilt.android.qualifiers.ApplicationContext
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.channels.awaitClose
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.callbackFlow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.launch
import javax.inject.Inject

class FusedPositionService @Inject constructor(
    @ApplicationContext private val context: Context,
    private val wifiRttService: WifiRttService?,
    private val locationService: LocationService
) {
    fun getFusedPositionFlow(): Flow<Location> = callbackFlow {
        val scope = CoroutineScope(Dispatchers.Default)
        var lastRttLocation: Location? = null
        var lastGpsLocation: Location? = null

        // Wi-Fi RTT updates
        if (wifiRttService != null && Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            scope.launch {
                wifiRttService.getRttLocationUpdates(1000L).collect { rttLoc ->
                    if (rttLoc != null && rttLoc.accuracy < 3f) {
                        lastRttLocation = rttLoc
                        trySend(rttLoc)
                    }
                }
            }
        }
        // GPS updates
        scope.launch {
            locationService.getLocationUpdates(200L).collect { gpsLoc ->
                lastGpsLocation = gpsLoc
                trySend(gpsLoc)
            }
        }
        awaitClose { /* Clean up if needed */ }
    }

    fun calculateDistance(lat1: Double, lon1: Double, lat2: Double, lon2: Double): Float {
        val results = FloatArray(1)
        android.location.Location.distanceBetween(lat1, lon1, lat2, lon2, results)
        return results[0]
    }
} 