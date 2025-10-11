package com.example.fyp

import android.app.Application
import android.app.PendingIntent
import android.os.Build
import androidx.work.Configuration
import androidx.work.WorkManager
import dagger.hilt.android.HiltAndroidApp

@HiltAndroidApp
class InNavigationApplication : Application() {
    override fun onCreate() {
        super.onCreate()
        
        // Initialize WorkManager with proper configuration for Android 12+
        val config = Configuration.Builder()
            .setMinimumLoggingLevel(android.util.Log.INFO)
            .build()
        WorkManager.initialize(this, config)
    }
} 