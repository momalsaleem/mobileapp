package com.example.fyp.viewmodel

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.example.fyp.data.entity.RouteEntity
import com.example.fyp.data.repository.RouteRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.*
import kotlinx.coroutines.launch
import javax.inject.Inject

@HiltViewModel
class RouteListViewModel @Inject constructor(
    private val routeRepository: RouteRepository
) : ViewModel() {

    private val _routes = MutableStateFlow<List<RouteEntity>>(emptyList())
    val routes: StateFlow<List<RouteEntity>> = _routes

    private val _isLoading = MutableStateFlow(true)
    val isLoading: StateFlow<Boolean> = _isLoading

    private val _errorMessage = MutableStateFlow<String?>(null)
    val errorMessage: StateFlow<String?> = _errorMessage

    init {
        loadRoutes()
    }

    private fun loadRoutes() {
        viewModelScope.launch {
            try {
                _isLoading.value = true
                routeRepository.getAllRoutes()
                    .catch { e ->
                        _errorMessage.value = "Failed to load routes: ${e.message}"
                    }
                    .collect { routes ->
                        _routes.value = routes
                        _isLoading.value = false
                    }
            } catch (e: Exception) {
                _errorMessage.value = "Failed to load routes: ${e.message}"
                _isLoading.value = false
            }
        }
    }

    fun deleteRoute(routeId: Long) {
        viewModelScope.launch {
            try {
                routeRepository.deleteRoute(routeId)
                // Routes will be automatically updated through the Flow
            } catch (e: Exception) {
                _errorMessage.value = "Failed to delete route: ${e.message}"
            }
        }
    }

    fun searchRoutes(query: String) {
        viewModelScope.launch {
            try {
                routeRepository.searchRoutes(query)
                    .catch { e ->
                        _errorMessage.value = "Search failed: ${e.message}"
                    }
                    .collect { routes ->
                        _routes.value = routes
                    }
            } catch (e: Exception) {
                _errorMessage.value = "Search failed: ${e.message}"
            }
        }
    }

    fun clearError() {
        _errorMessage.value = null
    }

    fun refreshRoutes() {
        loadRoutes()
    }

    fun deleteAllRoutes() {
        viewModelScope.launch {
            try {
                routeRepository.deleteAllRoutes()
                // Routes will be automatically updated through the Flow
            } catch (e: Exception) {
                _errorMessage.value = "Failed to delete all routes: ${e.message}"
            }
        }
    }
} 