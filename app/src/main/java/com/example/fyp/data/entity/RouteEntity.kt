package com.example.fyp.data.entity

import androidx.room.Entity
import androidx.room.PrimaryKey
import androidx.room.TypeConverters
import com.example.fyp.data.converter.DateConverter
import com.example.fyp.data.converter.LocationListConverter
import java.util.Date

@Entity(tableName = "routes")
@TypeConverters(DateConverter::class, LocationListConverter::class)
data class RouteEntity(
    @PrimaryKey(autoGenerate = true)
    val id: Long = 0,
    val name: String,
    val description: String,
    val startLocation: String,
    val endLocation: String,
    val duration: Int, // in seconds
    val distance: Float, // in meters
    val steps: Int,
    val locations: List<LocationPoint>,
    val createdAt: Date,
    val updatedAt: Date,
    val isActive: Boolean = true
)

data class LocationPoint(
    val latitude: Double,
    val longitude: Double,
    val altitude: Float,
    val timestamp: Long,
    val stepNumber: Int,
    val instruction: String? = null,
    val bearing: Float = 0f, // Direction in degrees (0-360)
    val isKeypoint: Boolean = false, // Whether this is a keypoint (turn, stairs, etc.)
    val keypointType: KeypointType = KeypointType.NONE // Type of keypoint
)

enum class KeypointType {
    NONE,
    TURN_LEFT,
    TURN_RIGHT,
    TURN_AROUND,
    STAIRS_UP,
    STAIRS_DOWN,
    ELEVATOR,
    DOOR,
    LANDMARK
} 