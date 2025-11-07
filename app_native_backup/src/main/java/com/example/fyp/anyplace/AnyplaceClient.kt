package com.example.fyp.anyplace

import retrofit2.Retrofit
import retrofit2.converter.gson.GsonConverterFactory

object AnyplaceClient {
    private const val BASE_URL = "https://anyplace.cs.ucy.ac.cy/anyplace/"

    val api: AnyplaceApi by lazy {
        Retrofit.Builder()
            .baseUrl(BASE_URL)
            .addConverterFactory(GsonConverterFactory.create())
            .build()
            .create(AnyplaceApi::class.java)
    }
} 