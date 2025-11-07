package com.example.fyp.viewmodel

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.example.fyp.service.AITrainingService
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.*
import kotlinx.coroutines.launch
import javax.inject.Inject

@HiltViewModel
class AITrainingViewModel @Inject constructor(
    private val aiTrainingService: AITrainingService
) : ViewModel() {

    val isCollectingData: StateFlow<Boolean> = aiTrainingService.isCollectingData
    val collectedImagesCount: StateFlow<Int> = aiTrainingService.collectedImagesCount
    val trainingProgress: StateFlow<Float> = aiTrainingService.trainingProgress

    private val _trainingStats = MutableStateFlow<AITrainingService.TrainingDataStats?>(null)
    val trainingStats: StateFlow<AITrainingService.TrainingDataStats?> = _trainingStats

    private val _showExportDialog = MutableStateFlow(false)
    val showExportDialog: StateFlow<Boolean> = _showExportDialog

    private val _showClearDialog = MutableStateFlow(false)
    val showClearDialog: StateFlow<Boolean> = _showClearDialog

    init {
        loadTrainingStats()
    }

    fun startDataCollection() {
        aiTrainingService.startDataCollection()
        loadTrainingStats()
    }

    fun stopDataCollection() {
        aiTrainingService.stopDataCollection()
        loadTrainingStats()
    }

    fun exportTrainingData() {
        viewModelScope.launch {
            val exportedFile = aiTrainingService.exportTrainingData()
            exportedFile?.let {
                // File exported successfully
                loadTrainingStats()
            }
        }
    }

    fun clearTrainingData() {
        aiTrainingService.clearTrainingData()
        loadTrainingStats()
    }

    fun showExportDialog() {
        _showExportDialog.value = true
    }

    fun hideExportDialog() {
        _showExportDialog.value = false
    }

    fun showClearDataDialog() {
        _showClearDialog.value = true
    }

    fun hideClearDialog() {
        _showClearDialog.value = false
    }

    private fun loadTrainingStats() {
        viewModelScope.launch {
            _trainingStats.value = aiTrainingService.getTrainingDataStats()
        }
    }
} 