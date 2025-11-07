package com.example.fyp.screens

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.navigation.NavController
import androidx.hilt.navigation.compose.hiltViewModel
import com.example.fyp.service.AITrainingService
import com.example.fyp.viewmodel.AITrainingViewModel
import java.text.SimpleDateFormat
import java.util.*

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun AITrainingScreen(
    navController: NavController,
    viewModel: AITrainingViewModel = hiltViewModel()
) {
    val context = LocalContext.current
    val isCollectingData by viewModel.isCollectingData.collectAsState()
    val collectedImagesCount by viewModel.collectedImagesCount.collectAsState()
    val trainingStats by viewModel.trainingStats.collectAsState()
    val showExportDialog by viewModel.showExportDialog.collectAsState()
    val showClearDialog by viewModel.showClearDialog.collectAsState()

    Scaffold(
        topBar = {
            TopAppBar(
                title = {
                    Text(
                        text = "AI Training",
                        style = MaterialTheme.typography.headlineMedium.copy(
                            fontWeight = FontWeight.Bold
                        )
                    )
                },
                navigationIcon = {
                    IconButton(
                        onClick = { navController.navigateUp() }
                    ) {
                        Icon(
                            imageVector = Icons.Default.ArrowBack,
                            contentDescription = "Back"
                        )
                    }
                },
                colors = TopAppBarDefaults.topAppBarColors(
                    containerColor = MaterialTheme.colorScheme.surface
                )
            )
        }
    ) { paddingValues ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues)
                .verticalScroll(rememberScrollState())
        ) {
            // Training Status Card
            Card(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(16.dp),
                colors = CardDefaults.cardColors(
                    containerColor = if (isCollectingData) 
                        MaterialTheme.colorScheme.primaryContainer 
                    else 
                        MaterialTheme.colorScheme.surfaceVariant
                )
            ) {
                Column(
                    modifier = Modifier.padding(16.dp)
                ) {
                    Row(
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Icon(
                            imageVector = if (isCollectingData) Icons.Default.RadioButtonChecked else Icons.Default.RadioButtonUnchecked,
                            contentDescription = "Training Status",
                            tint = if (isCollectingData) 
                                MaterialTheme.colorScheme.onPrimaryContainer 
                            else 
                                MaterialTheme.colorScheme.onSurfaceVariant
                        )
                        Spacer(modifier = Modifier.width(8.dp))
                        Text(
                            text = if (isCollectingData) "Collecting Training Data" else "Training Data Collection Stopped",
                            style = MaterialTheme.typography.titleMedium,
                            fontWeight = FontWeight.Bold,
                            color = if (isCollectingData) 
                                MaterialTheme.colorScheme.onPrimaryContainer 
                            else 
                                MaterialTheme.colorScheme.onSurfaceVariant
                        )
                    }
                    
                    Spacer(modifier = Modifier.height(12.dp))
                    
                    Text(
                        text = "Images Collected: $collectedImagesCount / 1000",
                        style = MaterialTheme.typography.bodyMedium,
                        color = if (isCollectingData) 
                            MaterialTheme.colorScheme.onPrimaryContainer 
                        else 
                            MaterialTheme.colorScheme.onSurfaceVariant
                    )
                    
                    if (isCollectingData) {
                        Spacer(modifier = Modifier.height(8.dp))
                        LinearProgressIndicator(
                            progress = collectedImagesCount / 1000f,
                            modifier = Modifier.fillMaxWidth(),
                            color = MaterialTheme.colorScheme.onPrimaryContainer
                        )
                    }
                }
            }

            // Training Controls
            Card(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(16.dp)
            ) {
                Column(
                    modifier = Modifier.padding(16.dp)
                ) {
                    Text(
                        text = "Training Controls",
                        style = MaterialTheme.typography.titleMedium,
                        fontWeight = FontWeight.Bold
                    )
                    
                    Spacer(modifier = Modifier.height(16.dp))
                    
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceEvenly
                    ) {
                        Button(
                            onClick = { viewModel.startDataCollection() },
                            enabled = !isCollectingData && collectedImagesCount < 1000,
                            colors = ButtonDefaults.buttonColors(
                                containerColor = MaterialTheme.colorScheme.primary
                            )
                        ) {
                            Icon(
                                imageVector = Icons.Default.PlayArrow,
                                contentDescription = "Start Collection"
                            )
                            Spacer(modifier = Modifier.width(8.dp))
                            Text("Start Collection")
                        }
                        
                        Button(
                            onClick = { viewModel.stopDataCollection() },
                            enabled = isCollectingData,
                            colors = ButtonDefaults.buttonColors(
                                containerColor = MaterialTheme.colorScheme.error
                            )
                        ) {
                            Icon(
                                imageVector = Icons.Default.Stop,
                                contentDescription = "Stop Collection"
                            )
                            Spacer(modifier = Modifier.width(8.dp))
                            Text("Stop Collection")
                        }
                    }
                }
            }

            // Training Statistics
            Card(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(16.dp)
            ) {
                Column(
                    modifier = Modifier.padding(16.dp)
                ) {
                    Text(
                        text = "Training Data Statistics",
                        style = MaterialTheme.typography.titleMedium,
                        fontWeight = FontWeight.Bold
                    )
                    
                    Spacer(modifier = Modifier.height(16.dp))
                    
                    trainingStats?.let { stats ->
                        StatRow("Total Images", "${stats.totalImages}")
                        StatRow("Total Objects", "${stats.totalObjects}")
                        StatRow("Unique Categories", "${stats.uniqueCategories}")
                        StatRow("Navigation Hazards", "${stats.hazardCount}")
                        StatRow("User Corrections", "${stats.correctionsCount}")
                        StatRow("Storage Used", "${formatFileSize(stats.storageUsed)}")
                    } ?: run {
                        Text(
                            text = "No training data available",
                            style = MaterialTheme.typography.bodyMedium,
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                    }
                }
            }

            // Data Management
            Card(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(16.dp)
            ) {
                Column(
                    modifier = Modifier.padding(16.dp)
                ) {
                    Text(
                        text = "Data Management",
                        style = MaterialTheme.typography.titleMedium,
                        fontWeight = FontWeight.Bold
                    )
                    
                    Spacer(modifier = Modifier.height(16.dp))
                    
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceEvenly
                    ) {
                        Button(
                            onClick = { viewModel.exportTrainingData() },
                            enabled = collectedImagesCount > 0,
                            colors = ButtonDefaults.buttonColors(
                                containerColor = MaterialTheme.colorScheme.secondary
                            )
                        ) {
                            Icon(
                                imageVector = Icons.Default.Download,
                                contentDescription = "Export Data"
                            )
                            Spacer(modifier = Modifier.width(8.dp))
                            Text("Export Data")
                        }
                        
                        Button(
                            onClick = { viewModel.showClearDataDialog() },
                            enabled = collectedImagesCount > 0,
                            colors = ButtonDefaults.buttonColors(
                                containerColor = MaterialTheme.colorScheme.error
                            )
                        ) {
                            Icon(
                                imageVector = Icons.Default.Delete,
                                contentDescription = "Clear Data"
                            )
                            Spacer(modifier = Modifier.width(8.dp))
                            Text("Clear Data")
                        }
                    }
                }
            }

            // Instructions
            Card(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(16.dp)
            ) {
                Column(
                    modifier = Modifier.padding(16.dp)
                ) {
                    Text(
                        text = "How to Train Your AI",
                        style = MaterialTheme.typography.titleMedium,
                        fontWeight = FontWeight.Bold
                    )
                    
                    Spacer(modifier = Modifier.height(12.dp))
                    
                    InstructionStep(
                        number = 1,
                        title = "Start Collection",
                        description = "Tap 'Start Collection' to begin collecting training data"
                    )
                    
                    InstructionStep(
                        number = 2,
                        title = "Record Routes",
                        description = "Go to 'Record Route' and walk around while the camera detects objects"
                    )
                    
                    InstructionStep(
                        number = 3,
                        title = "Point Camera at Objects",
                        description = "Point your camera at various objects like doors, stairs, people, etc."
                    )
                    
                    InstructionStep(
                        number = 4,
                        title = "Export Data",
                        description = "Export the collected data to train a custom model on your computer"
                    )
                    
                    InstructionStep(
                        number = 5,
                        title = "Replace Model",
                        description = "Replace the default model with your trained model for better accuracy"
                    )
                }
            }

            Spacer(modifier = Modifier.height(32.dp))
        }

        // Export Dialog
        if (showExportDialog) {
            AlertDialog(
                onDismissRequest = { viewModel.hideExportDialog() },
                title = { Text("Export Training Data") },
                text = { 
                    Text(
                        "Training data will be exported to your device's external storage. " +
                        "You can use this data to train a custom AI model on your computer."
                    )
                },
                confirmButton = {
                    Button(
                        onClick = { 
                            viewModel.exportTrainingData()
                            viewModel.hideExportDialog()
                        }
                    ) {
                        Text("Export")
                    }
                },
                dismissButton = {
                    TextButton(
                        onClick = { viewModel.hideExportDialog() }
                    ) {
                        Text("Cancel")
                    }
                }
            )
        }

        // Clear Data Dialog
        if (showClearDialog) {
            AlertDialog(
                onDismissRequest = { viewModel.hideClearDialog() },
                title = { Text("Clear Training Data") },
                text = { 
                    Text(
                        "This will permanently delete all collected training data. " +
                        "This action cannot be undone."
                    )
                },
                confirmButton = {
                    Button(
                        onClick = { 
                            viewModel.clearTrainingData()
                            viewModel.hideClearDialog()
                        },
                        colors = ButtonDefaults.buttonColors(
                            containerColor = MaterialTheme.colorScheme.error
                        )
                    ) {
                        Text("Clear All Data")
                    }
                },
                dismissButton = {
                    TextButton(
                        onClick = { viewModel.hideClearDialog() }
                    ) {
                        Text("Cancel")
                    }
                }
            )
        }
    }
}

@Composable
private fun StatRow(label: String, value: String) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(vertical = 4.dp),
        horizontalArrangement = Arrangement.SpaceBetween
    ) {
        Text(
            text = label,
            style = MaterialTheme.typography.bodyMedium
        )
        Text(
            text = value,
            style = MaterialTheme.typography.bodyMedium,
            fontWeight = FontWeight.Bold
        )
    }
}

@Composable
private fun InstructionStep(
    number: Int,
    title: String,
    description: String
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(vertical = 8.dp),
        verticalAlignment = Alignment.Top
    ) {
        Card(
            modifier = Modifier.size(24.dp),
            colors = CardDefaults.cardColors(
                containerColor = MaterialTheme.colorScheme.primary
            )
        ) {
            Box(
                modifier = Modifier.fillMaxSize(),
                contentAlignment = Alignment.Center
            ) {
                Text(
                    text = number.toString(),
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onPrimary,
                    fontWeight = FontWeight.Bold
                )
            }
        }
        
        Spacer(modifier = Modifier.width(12.dp))
        
        Column {
            Text(
                text = title,
                style = MaterialTheme.typography.bodyMedium,
                fontWeight = FontWeight.Bold
            )
            Text(
                text = description,
                style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
        }
    }
}

private fun formatFileSize(bytes: Long): String {
    return when {
        bytes < 1024 -> "$bytes B"
        bytes < 1024 * 1024 -> "${bytes / 1024} KB"
        bytes < 1024 * 1024 * 1024 -> "${bytes / (1024 * 1024)} MB"
        else -> "${bytes / (1024 * 1024 * 1024)} GB"
    }
} 