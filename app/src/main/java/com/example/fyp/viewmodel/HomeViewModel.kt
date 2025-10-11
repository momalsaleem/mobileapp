package com.example.fyp.viewmodel

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.example.fyp.data.repository.RouteRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.launch
import javax.inject.Inject

@HiltViewModel
class HomeViewModel @Inject constructor(
    private val routeRepository: RouteRepository
) : ViewModel() {

    private val _routeCount = MutableStateFlow(0)
    val routeCount: StateFlow<Int> = _routeCount

    private val _isLoading = MutableStateFlow(true)
    val isLoading: StateFlow<Boolean> = _isLoading

    init {
        loadRouteCount()
    }

    private fun loadRouteCount() {
        viewModelScope.launch {
            try {
                _isLoading.value = true
                val count = routeRepository.getRouteCount()
                _routeCount.value = count
                _isLoading.value = false
            } catch (e: Exception) {
                _isLoading.value = false
                // Set a default value to prevent issues
                _routeCount.value = 0
                // Log the error for debugging
                android.util.Log.e("HomeViewModel", "Error loading route count", e)
            }
        }
    }

    fun refreshData() {
        loadRouteCount()
    }
} 