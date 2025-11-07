package com.example.fyp.data.converter

import androidx.room.TypeConverter
import com.example.fyp.data.entity.LocationPoint
import com.google.gson.Gson
import com.google.gson.reflect.TypeToken

class LocationListConverter {
    private val gson = Gson()

    @TypeConverter
    fun fromLocationList(value: List<LocationPoint>): String {
        return gson.toJson(value)
    }

    @TypeConverter
    fun toLocationList(value: String): List<LocationPoint> {
        val listType = object : TypeToken<List<LocationPoint>>() {}.type
        return gson.fromJson(value, listType)
    }
} 