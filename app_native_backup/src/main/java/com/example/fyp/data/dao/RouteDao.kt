package com.example.fyp.data.dao

import androidx.room.*
import com.example.fyp.data.entity.RouteEntity
import kotlinx.coroutines.flow.Flow

@Dao
interface RouteDao {
    @Query("SELECT * FROM routes WHERE isActive = 1 ORDER BY createdAt DESC")
    fun getAllRoutes(): Flow<List<RouteEntity>>

    @Query("SELECT * FROM routes WHERE id = :routeId")
    suspend fun getRouteById(routeId: Long): RouteEntity?

    @Query("SELECT * FROM routes WHERE name LIKE '%' || :query || '%' OR description LIKE '%' || :query || '%'")
    fun searchRoutes(query: String): Flow<List<RouteEntity>>

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertRoute(route: RouteEntity): Long

    @Update
    suspend fun updateRoute(route: RouteEntity)

    @Query("UPDATE routes SET isActive = 0 WHERE id = :routeId")
    suspend fun deleteRoute(routeId: Long)

    @Query("DELETE FROM routes WHERE id = :routeId")
    suspend fun permanentlyDeleteRoute(routeId: Long)

    @Query("DELETE FROM routes")
    suspend fun deleteAllRoutes()

    @Query("SELECT COUNT(*) FROM routes WHERE isActive = 1")
    suspend fun getRouteCount(): Int

    @Query("SELECT * FROM routes WHERE isActive = 1 ORDER BY updatedAt DESC LIMIT :limit")
    fun getRecentRoutes(limit: Int): Flow<List<RouteEntity>>
} 