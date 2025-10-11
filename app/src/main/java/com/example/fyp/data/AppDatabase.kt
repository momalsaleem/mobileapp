package com.example.fyp.data

import androidx.room.Database
import androidx.room.Room
import androidx.room.RoomDatabase
import androidx.room.TypeConverters
import android.content.Context
import com.example.fyp.data.converter.DateConverter
import com.example.fyp.data.converter.LocationListConverter
import com.example.fyp.data.dao.RouteDao
import com.example.fyp.data.entity.RouteEntity

@Database(
    entities = [RouteEntity::class],
    version = 1,
    exportSchema = false
)
@TypeConverters(DateConverter::class, LocationListConverter::class)
abstract class AppDatabase : RoomDatabase() {
    abstract fun routeDao(): RouteDao

    companion object {
        @Volatile
        private var INSTANCE: AppDatabase? = null

        fun getDatabase(context: Context): AppDatabase {
            return INSTANCE ?: synchronized(this) {
                try {
                    val instance = Room.databaseBuilder(
                        context.applicationContext,
                        AppDatabase::class.java,
                        "in_navigation_database"
                    )
                    .fallbackToDestructiveMigration()
                    .build()
                    INSTANCE = instance
                    instance
                } catch (e: Exception) {
                    android.util.Log.e("AppDatabase", "Error creating database", e)
                    throw e
                }
            }
        }
    }
} 