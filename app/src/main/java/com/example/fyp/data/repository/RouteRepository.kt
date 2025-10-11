package com.example.fyp.data.repository

import com.example.fyp.data.dao.RouteDao
import com.example.fyp.data.entity.RouteEntity
import com.example.fyp.data.entity.LocationPoint
import kotlinx.coroutines.flow.Flow
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class RouteRepository @Inject constructor(
    private val routeDao: RouteDao
) {
    fun getAllRoutes(): Flow<List<RouteEntity>> = routeDao.getAllRoutes()

    suspend fun getRouteById(routeId: Long): RouteEntity? = routeDao.getRouteById(routeId)

    fun searchRoutes(query: String): Flow<List<RouteEntity>> = routeDao.searchRoutes(query)

    suspend fun insertRoute(route: RouteEntity): Long = routeDao.insertRoute(route)

    suspend fun updateRoute(route: RouteEntity) = routeDao.updateRoute(route)

    suspend fun deleteRoute(routeId: Long) = routeDao.deleteRoute(routeId)

    suspend fun permanentlyDeleteRoute(routeId: Long) = routeDao.permanentlyDeleteRoute(routeId)

    suspend fun deleteAllRoutes() = routeDao.deleteAllRoutes()

    suspend fun getRouteCount(): Int = routeDao.getRouteCount()

    fun getRecentRoutes(limit: Int): Flow<List<RouteEntity>> = routeDao.getRecentRoutes(limit)

    suspend fun createRoute(
        name: String,
        description: String,
        startLocation: String,
        endLocation: String,
        locations: List<LocationPoint>
    ): Long {
        val route = RouteEntity(
            name = name,
            description = description,
            startLocation = startLocation,
            endLocation = endLocation,
            duration = calculateDuration(locations),
            distance = calculateDistance(locations),
            steps = locations.size,
            locations = locations,
            createdAt = java.util.Date(),
            updatedAt = java.util.Date()
        )
        return insertRoute(route)
    }

    private fun calculateDuration(locations: List<LocationPoint>): Int {
        if (locations.size < 2) return 0
        val firstTimestamp = locations.first().timestamp
        val lastTimestamp = locations.last().timestamp
        return ((lastTimestamp - firstTimestamp) / 1000).toInt()
    }

    private fun calculateDistance(locations: List<LocationPoint>): Float {
        if (locations.size < 2) return 0f
        var totalDistance = 0f
        for (i in 0 until locations.size - 1) {
            totalDistance += calculateDistanceBetweenPoints(
                locations[i],
                locations[i + 1]
            )
        }
        return totalDistance
    }

    private fun calculateDistanceBetweenPoints(point1: LocationPoint, point2: LocationPoint): Float {
        val results = FloatArray(1)
        android.location.Location.distanceBetween(
            point1.latitude,
            point1.longitude,
            point2.latitude,
            point2.longitude,
            results
        )
        return results[0]
    }
} 