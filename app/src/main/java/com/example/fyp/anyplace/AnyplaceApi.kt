package com.example.fyp.anyplace

import retrofit2.http.GET
import retrofit2.http.Query
import retrofit2.Call

// Data class for the API response
data class AnyplaceLocation(
    val lat: Double,
    val lon: Double,
    val floor_number: String,
    val buid: String
)

interface AnyplaceApi {
    @GET("anyplace/mapping/position")
    fun getIndoorLocation(
        @Query("lat") lat: Double,
        @Query("lon") lon: Double,
        @Query("buid") buildingId: String,
        @Query("floor_number") floor: String
    ): Call<AnyplaceLocation>
} 