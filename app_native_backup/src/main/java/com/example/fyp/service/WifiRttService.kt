package com.example.fyp.service

import android.Manifest
import android.annotation.SuppressLint
import android.content.Context
import android.content.pm.PackageManager
import android.location.Location
import android.net.wifi.rtt.*
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.util.Log
import androidx.annotation.RequiresApi
import androidx.core.app.ActivityCompat
import dagger.hilt.android.qualifiers.ApplicationContext
import kotlinx.coroutines.channels.awaitClose
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.callbackFlow
import javax.inject.Inject

@RequiresApi(Build.VERSION_CODES.P)
class WifiRttService @Inject constructor(
    @ApplicationContext private val context: Context
) {
    private val wifiRttManager: WifiRttManager? =
        context.getSystemService(Context.WIFI_RTT_RANGING_SERVICE) as? WifiRttManager

    @SuppressLint("MissingPermission")
    fun getRttLocationUpdates(intervalMs: Long = 2000L): Flow<Location?> = callbackFlow {
        if (wifiRttManager == null) {
            Log.w("WifiRttService", "Wi-Fi RTT not supported on this device")
            close()
            return@callbackFlow
        }
        if (ActivityCompat.checkSelfPermission(context, Manifest.permission.ACCESS_FINE_LOCATION) != PackageManager.PERMISSION_GRANTED) {
            close(SecurityException("Location permission not granted for Wi-Fi RTT"))
            return@callbackFlow
        }
        val handler = Handler(Looper.getMainLooper())
        val scanRunnable = object : Runnable {
            override fun run() {
                val config = RangingRequest.Builder()
                    .addAccessPoints(getRttCapableAps())
                    .build()
                wifiRttManager.startRanging(config, context.mainExecutor, object : RangingResultCallback() {
                    override fun onRangingResults(results: List<RangingResult>) {
                        val validResults = results.filter { it.status == RangingResult.STATUS_SUCCESS }
                        if (validResults.isNotEmpty()) {
                            // Use the closest AP for now (could do multilateration for better accuracy)
                            val closest = validResults.minByOrNull { it.distanceMm }
                            val location = Location("wifi_rtt").apply {
                                latitude = 0.0 // Unknown, but could be set if AP location is known
                                longitude = 0.0
                                accuracy = (closest?.distanceMm ?: 0) / 1000f
                            }
                            trySend(location)
                        } else {
                            trySend(null)
                        }
                    }
                    override fun onRangingFailure(code: Int) {
                        Log.w("WifiRttService", "Ranging failed: $code")
                        trySend(null)
                    }
                })
                handler.postDelayed(this, intervalMs)
            }
        }
        handler.post(scanRunnable)
        awaitClose { handler.removeCallbacks(scanRunnable) }
    }

    private fun getRttCapableAps(): List<android.net.wifi.ScanResult> {
        val wifiManager = context.getSystemService(Context.WIFI_SERVICE) as? android.net.wifi.WifiManager
        val scanResults = wifiManager?.scanResults ?: emptyList()
        return scanResults.filter { it.is80211mcResponder }
    }
} 