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
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.navigation.NavController
import androidx.lifecycle.viewmodel.compose.viewModel
import androidx.hilt.navigation.compose.hiltViewModel
import com.example.fyp.viewmodel.RouteListViewModel
import com.example.fyp.service.DeviceCompatibilityService
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import com.example.fyp.service.VoiceFeedbackService

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun SettingsScreen(navController: NavController) {
    var highContrastMode by remember { mutableStateOf(false) }
    var audioFeedback by remember { mutableStateOf(true) }
    var hapticFeedback by remember { mutableStateOf(true) }
    var autoSaveRoutes by remember { mutableStateOf(true) }
    var locationAccuracy by remember { mutableStateOf("High") }
    var voiceSpeed by remember { mutableStateOf(1.0f) }
    var showClearDialog by remember { mutableStateOf(false) }
    var showSuccessDialog by remember { mutableStateOf(false) }
    val viewModel: RouteListViewModel = hiltViewModel()
    val coroutineScope = rememberCoroutineScope()
    val context = LocalContext.current
    val voiceFeedback = remember { VoiceFeedbackService.getInstance(context) }
    val deviceCompatibilityService = remember { DeviceCompatibilityService(context) }

    Scaffold(
        topBar = {
            TopAppBar(
                title = {
                    Text(
                        text = "Settings",
                        style = MaterialTheme.typography.headlineMedium.copy(
                            fontWeight = FontWeight.Bold
                        )
                    )
                },
                navigationIcon = {
                    IconButton(
                        onClick = { navController.navigateUp() },
                        modifier = Modifier.testTag("back_button")
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
            // Accessibility Section
            SettingsSection(
                title = "Accessibility",
                icon = Icons.Default.Accessibility
            ) {
                SettingsSwitch(
                    title = "High Contrast Mode",
                    subtitle = "Increase contrast for better visibility",
                    checked = highContrastMode,
                    onCheckedChange = {
                        highContrastMode = it
                        voiceFeedback.speak("High Contrast Mode ${if (it) "enabled" else "disabled"}")
                    },
                    testTag = "high_contrast_switch"
                )
                
                SettingsSwitch(
                    title = "Audio Feedback",
                    subtitle = "Play sounds for navigation cues",
                    checked = audioFeedback,
                    onCheckedChange = {
                        audioFeedback = it
                        voiceFeedback.speak("Audio Feedback ${if (it) "enabled" else "disabled"}")
                    },
                    testTag = "audio_feedback_switch"
                )
                
                SettingsSwitch(
                    title = "Haptic Feedback",
                    subtitle = "Vibrate for important events",
                    checked = hapticFeedback,
                    onCheckedChange = {
                        hapticFeedback = it
                        voiceFeedback.speak("Haptic Feedback ${if (it) "enabled" else "disabled"}")
                    },
                    testTag = "haptic_feedback_switch"
                )
                
                SettingsSlider(
                    title = "Voice Speed",
                    subtitle = "Adjust speech rate for navigation",
                    value = voiceSpeed,
                    onValueChange = {
                        voiceSpeed = it
                        voiceFeedback.speak("Voice speed set to ${String.format("%.1f", it)} times")
                    },
                    valueRange = 0.5f..2.0f,
                    steps = 15,
                    testTag = "voice_speed_slider"
                )
            }

            // Navigation Section
            SettingsSection(
                title = "Navigation",
                icon = Icons.Default.Navigation
            ) {
                SettingsSwitch(
                    title = "Auto-save Routes",
                    subtitle = "Automatically save completed routes",
                    checked = autoSaveRoutes,
                    onCheckedChange = { autoSaveRoutes = it },
                    testTag = "auto_save_switch"
                )
                
                SettingsDropdown(
                    title = "Location Accuracy",
                    subtitle = "Set GPS accuracy level",
                    selectedValue = locationAccuracy,
                    onValueChange = { locationAccuracy = it },
                    options = listOf("Low", "Medium", "High", "Maximum"),
                    testTag = "location_accuracy_dropdown"
                )

                // Add navigation button
                SettingsItem(
                    title = "Start Navigation",
                    subtitle = "Go to navigation screen to follow a saved route",
                    icon = Icons.Default.Navigation,
                    onClick = {
                        voiceFeedback.speak("Start Navigation")
                        navController.navigate("navigate_route")
                    },
                    testTag = "start_navigation_button"
                )
            }

            // Device Compatibility Section
            SettingsSection(
                title = "Device Compatibility",
                icon = Icons.Default.PhoneAndroid
            ) {
                val deviceInfo = deviceCompatibilityService.getDeviceInfo()
                val arSupport = deviceCompatibilityService.checkARCoreSupport()
                val cameraSupport = deviceCompatibilityService.checkCameraSupport()
                val locationSupport = deviceCompatibilityService.checkLocationSupport()
                val isCompatible = deviceCompatibilityService.isDeviceCompatible()
                val recommendedMode = deviceCompatibilityService.getRecommendedMode()
                
                Card(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(vertical = 8.dp),
                    colors = CardDefaults.cardColors(
                        containerColor = if (isCompatible) 
                            MaterialTheme.colorScheme.primaryContainer 
                        else 
                            MaterialTheme.colorScheme.errorContainer
                    )
                ) {
                    Column(
                        modifier = Modifier.padding(16.dp)
                    ) {
                        Row(
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Icon(
                                imageVector = if (isCompatible) Icons.Default.CheckCircle else Icons.Default.Warning,
                                contentDescription = "Compatibility Status",
                                tint = if (isCompatible) 
                                    MaterialTheme.colorScheme.onPrimaryContainer 
                                else 
                                    MaterialTheme.colorScheme.onErrorContainer
                            )
                            Spacer(modifier = Modifier.width(8.dp))
                            Text(
                                text = if (isCompatible) "Device Compatible" else "Limited Compatibility",
                                style = MaterialTheme.typography.titleMedium,
                                fontWeight = FontWeight.Bold,
                                color = if (isCompatible) 
                                    MaterialTheme.colorScheme.onPrimaryContainer 
                                else 
                                    MaterialTheme.colorScheme.onErrorContainer
                            )
                        }
                        
                        Spacer(modifier = Modifier.height(12.dp))
                        
                        Text(
                            text = "Device: ${deviceInfo["manufacturer"]} ${deviceInfo["model"]}",
                            style = MaterialTheme.typography.bodyMedium,
                            color = if (isCompatible) 
                                MaterialTheme.colorScheme.onPrimaryContainer 
                            else 
                                MaterialTheme.colorScheme.onErrorContainer
                        )
                        Text(
                            text = "Android: ${deviceInfo["android_version"]} (API ${deviceInfo["api_level"]})",
                            style = MaterialTheme.typography.bodyMedium,
                            color = if (isCompatible) 
                                MaterialTheme.colorScheme.onPrimaryContainer 
                            else 
                                MaterialTheme.colorScheme.onErrorContainer
                        )
                        Text(
                            text = "Recommended Mode: $recommendedMode",
                            style = MaterialTheme.typography.bodyMedium,
                            fontWeight = FontWeight.Bold,
                            color = if (isCompatible) 
                                MaterialTheme.colorScheme.onPrimaryContainer 
                            else 
                                MaterialTheme.colorScheme.onErrorContainer
                        )
                    }
                }
                
                SettingsItem(
                    title = "AR Support",
                    subtitle = arSupport.name.replace("_", " "),
                    icon = if (arSupport == DeviceCompatibilityService.ARSupport.ARCORE_SUPPORTED) 
                        Icons.Default.CheckCircle 
                    else 
                        Icons.Default.Cancel,
                    onClick = { },
                    testTag = "ar_support_info",
                    isInfo = true
                )
                
                SettingsItem(
                    title = "Camera Support",
                    subtitle = cameraSupport.name.replace("_", " "),
                    icon = if (cameraSupport == DeviceCompatibilityService.CameraSupport.CAMERA_SUPPORTED) 
                        Icons.Default.CheckCircle 
                    else 
                        Icons.Default.Cancel,
                    onClick = { },
                    testTag = "camera_support_info",
                    isInfo = true
                )
                
                SettingsItem(
                    title = "Location Support",
                    subtitle = locationSupport.name.replace("_", " "),
                    icon = if (locationSupport == DeviceCompatibilityService.LocationSupport.LOCATION_SUPPORTED) 
                        Icons.Default.CheckCircle 
                    else 
                        Icons.Default.Cancel,
                    onClick = { },
                    testTag = "location_support_info",
                    isInfo = true
                )
            }

            // AI Training Section
            SettingsSection(
                title = "AI Training",
                icon = Icons.Default.Psychology
            ) {
                SettingsItem(
                    title = "AI Training Data",
                    subtitle = "Collect and manage training data for better detection",
                    icon = Icons.Default.DataUsage,
                    onClick = {
                        voiceFeedback.speak("AI Training Data")
                        navController.navigate("ai_training")
                    },
                    testTag = "ai_training_button"
                )
            }

            // App Section
            SettingsSection(
                title = "App",
                icon = Icons.Default.Apps
            ) {
                SettingsItem(
                    title = "About In Navigation",
                    subtitle = "Version 1.0.0",
                    icon = Icons.Default.Info,
                    onClick = {
                        voiceFeedback.speak("About In Navigation")
                        /* Show about dialog */
                    },
                    testTag = "about_button"
                )
            }

            // Data Section
            SettingsSection(
                title = "Data",
                icon = Icons.Default.Storage
            ) {
                SettingsItem(
                    title = "Clear All Data",
                    subtitle = "Delete all routes and settings",
                    icon = Icons.Default.DeleteForever,
                    onClick = {
                        voiceFeedback.speak("Clear All Data")
                        showClearDialog = true
                    },
                    testTag = "clear_data_button",
                    isDestructive = true
                )
            }
            if (showClearDialog) {
                AlertDialog(
                    onDismissRequest = { showClearDialog = false },
                    title = { Text("Clear All Data") },
                    text = { Text("Are you sure you want to delete all routes and reset all settings? This cannot be undone.") },
                    confirmButton = {
                        Button(onClick = {
                            showClearDialog = false
                            coroutineScope.launch {
                                viewModel.deleteAllRoutes()
                                // Reset settings to default
                                highContrastMode = false
                                audioFeedback = true
                                hapticFeedback = true
                                autoSaveRoutes = true
                                locationAccuracy = "High"
                                voiceSpeed = 1.0f
                                showSuccessDialog = true
                            }
                        }) { Text("Confirm") }
                    },
                    dismissButton = {
                        TextButton(onClick = { showClearDialog = false }) { Text("Cancel") }
                    }
                )
            }
            if (showSuccessDialog) {
                AlertDialog(
                    onDismissRequest = { showSuccessDialog = false },
                    title = { Text("Data Cleared") },
                    text = { Text("All routes and settings have been cleared.") },
                    confirmButton = {
                        Button(onClick = { showSuccessDialog = false }) { Text("OK") }
                    }
                )
            }

            Spacer(modifier = Modifier.height(32.dp))
        }
    }
}

@Composable
fun SettingsSection(
    title: String,
    icon: androidx.compose.ui.graphics.vector.ImageVector,
    content: @Composable () -> Unit
) {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .padding(16.dp)
    ) {
        Row(
            verticalAlignment = Alignment.CenterVertically,
            modifier = Modifier.padding(bottom = 16.dp)
        ) {
            Icon(
                imageVector = icon,
                contentDescription = title,
                modifier = Modifier.size(24.dp),
                tint = MaterialTheme.colorScheme.primary
            )
            Spacer(modifier = Modifier.width(12.dp))
            Text(
                text = title,
                style = MaterialTheme.typography.titleLarge.copy(
                    fontWeight = FontWeight.Bold
                )
            )
        }
        content()
    }
}

@Composable
fun SettingsSwitch(
    title: String,
    subtitle: String,
    checked: Boolean,
    onCheckedChange: (Boolean) -> Unit,
    testTag: String
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(vertical = 8.dp)
            .testTag(testTag),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Column(
            modifier = Modifier.weight(1f)
        ) {
            Text(
                text = title,
                style = MaterialTheme.typography.titleMedium
            )
            Text(
                text = subtitle,
                style = MaterialTheme.typography.bodyMedium.copy(
                    color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.7f)
                )
            )
        }
        Switch(
            checked = checked,
            onCheckedChange = onCheckedChange
        )
    }
}

@Composable
fun SettingsSlider(
    title: String,
    subtitle: String,
    value: Float,
    onValueChange: (Float) -> Unit,
    valueRange: ClosedFloatingPointRange<Float>,
    steps: Int,
    testTag: String
) {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .padding(vertical = 8.dp)
            .testTag(testTag)
    ) {
        Text(
            text = title,
            style = MaterialTheme.typography.titleMedium
        )
        Text(
            text = subtitle,
            style = MaterialTheme.typography.bodyMedium.copy(
                color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.7f)
            )
        )
        Spacer(modifier = Modifier.height(8.dp))
        Slider(
            value = value,
            onValueChange = onValueChange,
            valueRange = valueRange,
            steps = steps
        )
        Text(
            text = "Speed: ${String.format("%.1f", value)}x",
            style = MaterialTheme.typography.bodySmall
        )
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun SettingsDropdown(
    title: String,
    subtitle: String,
    selectedValue: String,
    onValueChange: (String) -> Unit,
    options: List<String>,
    testTag: String
) {
    var expanded by remember { mutableStateOf(false) }

    Column(
        modifier = Modifier
            .fillMaxWidth()
            .padding(vertical = 8.dp)
            .testTag(testTag)
    ) {
        Text(
            text = title,
            style = MaterialTheme.typography.titleMedium
        )
        Text(
            text = subtitle,
            style = MaterialTheme.typography.bodyMedium.copy(
                color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.7f)
            )
        )
        Spacer(modifier = Modifier.height(8.dp))
        
        ExposedDropdownMenuBox(
            expanded = expanded,
            onExpandedChange = { expanded = it }
        ) {
            OutlinedTextField(
                value = selectedValue,
                onValueChange = {},
                readOnly = true,
                trailingIcon = { ExposedDropdownMenuDefaults.TrailingIcon(expanded = expanded) },
                modifier = Modifier.menuAnchor()
            )
            
            ExposedDropdownMenu(
                expanded = expanded,
                onDismissRequest = { expanded = false }
            ) {
                options.forEach { option ->
                    DropdownMenuItem(
                        text = { Text(option) },
                        onClick = {
                            onValueChange(option)
                            expanded = false
                        }
                    )
                }
            }
        }
    }
}

@Composable
fun SettingsItem(
    title: String,
    subtitle: String,
    icon: androidx.compose.ui.graphics.vector.ImageVector,
    onClick: () -> Unit,
    testTag: String,
    isDestructive: Boolean = false,
    isInfo: Boolean = false
) {
    Card(
        modifier = Modifier
            .fillMaxWidth()
            .padding(vertical = 4.dp)
            .testTag(testTag),
        onClick = onClick,
        colors = CardDefaults.cardColors(
            containerColor = MaterialTheme.colorScheme.surface
        ),
        elevation = CardDefaults.cardElevation(defaultElevation = 2.dp)
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Icon(
                imageVector = icon,
                contentDescription = title,
                modifier = Modifier.size(24.dp),
                tint = if (isDestructive) MaterialTheme.colorScheme.error else MaterialTheme.colorScheme.primary
            )
            
            Spacer(modifier = Modifier.width(16.dp))
            
            Column(
                modifier = Modifier.weight(1f)
            ) {
                Text(
                    text = title,
                    style = MaterialTheme.typography.titleMedium.copy(
                        color = if (isDestructive) MaterialTheme.colorScheme.error else MaterialTheme.colorScheme.onSurface
                    )
                )
                Text(
                    text = subtitle,
                    style = MaterialTheme.typography.bodyMedium.copy(
                        color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.7f)
                    )
                )
            }
            
            if (!isInfo) {
                Icon(
                    imageVector = Icons.Default.ArrowForward,
                    contentDescription = "Navigate",
                    tint = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.5f)
                )
            }
        }
    }
} 