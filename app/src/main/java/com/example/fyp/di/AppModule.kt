package com.example.fyp.di

import android.content.Context
import android.os.Build
import androidx.annotation.RequiresApi
import com.example.fyp.data.AppDatabase
import com.example.fyp.data.repository.RouteRepository
import com.example.fyp.service.FusedPositionService
import com.example.fyp.service.LocationService
import com.example.fyp.service.WifiRttService
import com.example.fyp.service.MediaPipeService
import com.example.fyp.service.DeviceCompatibilityService
import com.example.fyp.service.AITrainingService
import dagger.Module
import dagger.Provides
import dagger.hilt.InstallIn
import dagger.hilt.android.qualifiers.ApplicationContext
import dagger.hilt.components.SingletonComponent
import javax.inject.Singleton

@Module
@InstallIn(SingletonComponent::class)
object AppModule {

    @Provides
    @Singleton
    fun provideAppDatabase(@ApplicationContext context: Context): AppDatabase {
        try {
            return AppDatabase.getDatabase(context)
        } catch (e: Exception) {
            android.util.Log.e("AppModule", "Error providing AppDatabase", e)
            throw e
        }
    }

    @Provides
    @Singleton
    fun provideRouteRepository(database: AppDatabase): RouteRepository {
        return RouteRepository(database.routeDao())
    }

    @Provides
    @Singleton
    fun provideLocationService(@ApplicationContext context: Context): LocationService {
        return LocationService(context)
    }

    @Provides
    @Singleton
    fun provideWifiRttService(@ApplicationContext context: Context): WifiRttService? {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) WifiRttService(context) else null
    }

    @Provides
    @Singleton
    fun provideAITrainingService(@ApplicationContext context: Context): AITrainingService {
        return AITrainingService(context)
    }

    @Provides
    @Singleton
    fun provideMediaPipeService(
        @ApplicationContext context: Context,
        aiTrainingService: AITrainingService
    ): MediaPipeService {
        return MediaPipeService(context, aiTrainingService)
    }

    @Provides
    @Singleton
    fun provideDeviceCompatibilityService(@ApplicationContext context: Context): DeviceCompatibilityService {
        return DeviceCompatibilityService(context)
    }

    @Provides
    @Singleton
    fun provideFusedPositionService(
        @ApplicationContext context: Context,
        wifiRttService: WifiRttService?,
        locationService: LocationService
    ): FusedPositionService {
        return FusedPositionService(context, wifiRttService, locationService)
    }
} 