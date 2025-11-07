package com.example.fyp.model

data class Route(
    val name: String,
    val duration: String,
    val steps: String,
    val destination: String,
    val createdDate: String = ""
) 