package com.example.fyp.screens

import android.Manifest
import android.content.Context
import android.os.Build
import android.widget.Toast
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.camera.core.CameraSelector
import androidx.camera.core.Preview
import androidx.camera.lifecycle.ProcessCameraProvider
import androidx.camera.view.PreviewView
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.runtime.collectAsState  
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalLifecycleOwner
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.viewinterop.AndroidView
import androidx.core.content.ContextCompat
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.LifecycleOwner
import androidx.lifecycle.viewmodel.compose.viewModel
import com.example.fyp.viewmodel.RouteRecordingViewModel
import kotlinx.coroutines.launch
import androidx.compose.ui.graphics.Color   
import com.google.accompanist.permissions.ExperimentalPermissionsApi
import com.google.accompanist.permissions.rememberMultiplePermissionsState
import com.example.fyp.ui.components.CameraOverlay
import com.example.fyp.ui.components.CameraARView
import com.example.fyp.service.DeviceCompatibilityService
import androidx.compose.foundation.Canvas
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.drawscope.drawIntoCanvas
import androidx.compose.ui.graphics.nativeCanvas
import com.example.fyp.data.entity.KeypointType

@OptIn(ExperimentalMaterial3Api::class, ExperimentalPermissionsApi::class)
@Composable
fun RecordRouteScreen(
    navController: androidx.navigation.NavController,
    viewModel: RouteRecordingViewModel = hiltViewModel()
) {
    val context = LocalContext.current
    val lifecycleOwner = LocalLifecycleOwner.current
    val isRecording by viewModel.isRecording.collectAsState()
    val recordingTime by viewModel.recordingTime.collectAsState()
    val isSaving by viewModel.isSaving.collectAsState()
    val viewModelErrorMessage by viewModel.errorMessage.collectAsState()
    val recordedLocations by viewModel.recordedLocations.collectAsState()
    val keypoints by viewModel.keypoints.collectAsState()
    val cameraReady by viewModel.isCameraReady.collectAsState()
    
    // MediaPipe states
    val detectedObjects by viewModel.detectedObjects.collectAsState()
    val navigationHazards by viewModel.navigationHazards.collectAsState()
    val navigationGuidance by viewModel.navigationGuidance.collectAsState()
    val isMediaPipeProcessing by viewModel.isMediaPipeProcessing.collectAsState()
    
    // Device compatibility
    val deviceCompatibilityService = remember { DeviceCompatibilityService(context) }
    val arSupport by remember { mutableStateOf(deviceCompatibilityService.checkARCoreSupport()) }
    val recommendedMode by remember { mutableStateOf(deviceCompatibilityService.getRecommendedMode()) }
    
    // Permission state
    val permissionState = rememberMultiplePermissionsState(
        listOf(
            Manifest.permission.ACCESS_FINE_LOCATION,
            Manifest.permission.ACCESS_COARSE_LOCATION,
            Manifest.permission.CAMERA
        )
    )
    
    val snackbarHostState = remember { SnackbarHostState() }
    val scope = rememberCoroutineScope()

    var routeName by remember { mutableStateOf("") }
    var routeDescription by remember { mutableStateOf("") }
    var showNameDialog by remember { mutableStateOf(false) }
    var cameraStarted by remember { mutableStateOf(false) }
    var showCompatibilityDialog by remember { mutableStateOf(false) }
    val currentLocation by viewModel.currentLocation.collectAsState()

    // Request permissions on first launch
    LaunchedEffect(Unit) {
        if (!permissionState.allPermissionsGranted) {
            permissionState.launchMultiplePermissionRequest()
        }
    }

    // Start camera when permissions are granted
    LaunchedEffect(permissionState.allPermissionsGranted) {
        if (permissionState.allPermissionsGranted && !cameraStarted) {
            cameraStarted = true
        }
    }

    // Device compatibility check
    LaunchedEffect(Unit) {
        if (arSupport == DeviceCompatibilityService.ARSupport.ARCORE_NOT_SUPPORTED) {
            showCompatibilityDialog = true
        }
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = {
                    Text(
                        text = "Record Route",
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
        ) {
            // Camera Preview with MediaPipe Overlay
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .height(300.dp)
                    .background(Color.Black)
            ) {
                if (permissionState.allPermissionsGranted) {
                    AndroidView(
                        factory = { context ->
                            PreviewView(context).apply {
                                this.scaleType = PreviewView.ScaleType.FILL_CENTER
                            }
                        },
                        modifier = Modifier.fillMaxSize(),
                        update = { previewView ->
                            if (cameraStarted) {
                                viewModel.startCamera(lifecycleOwner, previewView)
                            }
                        }
                    )
                    
                    // MediaPipe Overlay
                    CameraOverlay(
                        detectedObjects = detectedObjects,
                        navigationHazards = navigationHazards,
                        navigationGuidance = navigationGuidance,
                        isProcessing = isMediaPipeProcessing,
                        keypoints = keypoints, // Pass keypoints here
                        modifier = Modifier.fillMaxSize()
                    )
                } else {
                    // Show permission request UI
                    Column(
                        modifier = Modifier
                            .fillMaxSize()
                            .padding(16.dp),
                        horizontalAlignment = Alignment.CenterHorizontally,
                        verticalArrangement = Arrangement.Center
                    ) {
                        Icon(
                            imageVector = Icons.Default.CameraAlt,
                            contentDescription = "Camera Permission Required",
                            modifier = Modifier.size(64.dp),
                            tint = Color.White
                        )
                        Spacer(modifier = Modifier.height(16.dp))
                        Text(
                            text = "Camera and Location permissions are required to record routes",
                            style = MaterialTheme.typography.bodyLarge,
                            color = Color.White,
                            textAlign = TextAlign.Center
                        )
                        Spacer(modifier = Modifier.height(16.dp))
                        Button(
                            onClick = { permissionState.launchMultiplePermissionRequest() },
                            colors = ButtonDefaults.buttonColors(
                                containerColor = MaterialTheme.colorScheme.primary
                            )
                        ) {
                            Text("Grant Permissions")
                        }
                    }
                }
            }

            // Navigation View (AR or Camera-based)
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .height(400.dp)
            ) {
                if (!permissionState.allPermissionsGranted) {
                    Text(
                        text = "Camera and Location permissions are required for navigation.",
                        color = Color.Red,
                        modifier = Modifier.align(Alignment.Center)
                    )
                } else {
                    // Show device compatibility info
                    Card(
                        modifier = Modifier
                            .align(Alignment.TopStart)
                            .padding(8.dp),
                        colors = CardDefaults.cardColors(
                            containerColor = MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.9f)
                        )
                    ) {
                        Column(
                            modifier = Modifier.padding(8.dp)
                        ) {
                            Text(
                                text = "Device Mode: $recommendedMode",
                                style = MaterialTheme.typography.bodySmall,
                                color = MaterialTheme.colorScheme.onSurfaceVariant
                            )
                            Text(
                                text = "AR Support: ${arSupport.name}",
                                style = MaterialTheme.typography.bodySmall,
                                color = MaterialTheme.colorScheme.onSurfaceVariant
                            )
                        }
                    }
                    
                    // Navigation guidance overlay
                    Card(
                        modifier = Modifier
                            .align(Alignment.TopCenter)
                            .padding(16.dp),
                        colors = CardDefaults.cardColors(
                            containerColor = MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.9f)
                        )
                    ) {
                        Column(
                            modifier = Modifier.padding(16.dp)
                        ) {
                            Text(
                                text = "Navigation Guidance",
                                style = MaterialTheme.typography.titleMedium,
                                fontWeight = FontWeight.Bold
                            )
                            Spacer(modifier = Modifier.height(8.dp))
                            Text(
                                text = navigationGuidance,
                                style = MaterialTheme.typography.bodyMedium
                            )
                            if (isMediaPipeProcessing) {
                                Spacer(modifier = Modifier.height(8.dp))
                                Row(
                                    verticalAlignment = Alignment.CenterVertically
                                ) {
                                    CircularProgressIndicator(
                                        modifier = Modifier.size(16.dp),
                                        strokeWidth = 2.dp
                                    )
                                    Spacer(modifier = Modifier.width(8.dp))
                                    Text(
                                        text = "Processing...",
                                        style = MaterialTheme.typography.bodySmall
                                    )
                                }
                            }
                        }
                    }
                    
                    // Keypoints display
                    if (keypoints.isNotEmpty()) {
                        Card(
                            modifier = Modifier
                                .align(Alignment.BottomStart)
                                .padding(16.dp),
                            colors = CardDefaults.cardColors(
                                containerColor = MaterialTheme.colorScheme.primaryContainer.copy(alpha = 0.9f)
                            )
                        ) {
                            Column(
                                modifier = Modifier.padding(16.dp)
                            ) {
                                Text(
                                    text = "Route Keypoints",
                                    style = MaterialTheme.typography.titleSmall,
                                    fontWeight = FontWeight.Bold
                                )
                                Spacer(modifier = Modifier.height(8.dp))
                                keypoints.take(3).forEachIndexed { index, keypoint ->
                                    Text(
                                        text = "${index + 1}. ${keypoint.keypointType.name}",
                                        style = MaterialTheme.typography.bodySmall,
                                        color = MaterialTheme.colorScheme.onPrimaryContainer
                                    )
                                    keypoint.instruction?.let { instruction ->
                                        Text(
                                            text = "   $instruction",
                                            style = MaterialTheme.typography.bodySmall,
                                            color = MaterialTheme.colorScheme.onPrimaryContainer.copy(alpha = 0.7f)
                                        )
                                    }
                                }
                                if (keypoints.size > 3) {
                                    Text(
                                        text = "... and ${keypoints.size - 3} more",
                                        style = MaterialTheme.typography.bodySmall,
                                        color = MaterialTheme.colorScheme.onPrimaryContainer.copy(alpha = 0.7f)
                                    )
                                }
                            }
                        }
                    }
                    
                    // Hazard indicator
                    if (navigationHazards.isNotEmpty()) {
                        Card(
                            modifier = Modifier
                                .align(Alignment.BottomEnd)
                                .padding(16.dp),
                            colors = CardDefaults.cardColors(
                                containerColor = MaterialTheme.colorScheme.errorContainer.copy(alpha = 0.9f)
                            )
                        ) {
                            Column(
                                modifier = Modifier.padding(16.dp)
                            ) {
                                Text(
                                    text = "Navigation Hazards",
                                    style = MaterialTheme.typography.titleSmall,
                                    fontWeight = FontWeight.Bold,
                                    color = MaterialTheme.colorScheme.onErrorContainer
                                )
                                Spacer(modifier = Modifier.height(8.dp))
                                navigationHazards.take(3).forEach { hazard ->
                                    Text(
                                        text = "• ${hazard.type.name}",
                                        style = MaterialTheme.typography.bodySmall,
                                        color = MaterialTheme.colorScheme.onErrorContainer
                                    )
                                }
                                if (navigationHazards.size > 3) {
                                    Text(
                                        text = "... and ${navigationHazards.size - 3} more",
                                        style = MaterialTheme.typography.bodySmall,
                                        color = MaterialTheme.colorScheme.onErrorContainer.copy(alpha = 0.7f)
                                    )
                                }
                            }
                        }
                    }
                }
                
                // Show error message if any
                if (!viewModelErrorMessage.isNullOrEmpty()) {
                    Text(
                        text = viewModelErrorMessage ?: "",
                        color = Color.Red,
                        modifier = Modifier.align(Alignment.BottomCenter).padding(8.dp)
                    )
                }
            }

            // Recording Controls
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(16.dp),
                horizontalArrangement = Arrangement.SpaceEvenly,
                verticalAlignment = Alignment.CenterVertically
            ) {
                if (!isRecording) {
                    Button(
                        onClick = { viewModel.startRecording() },
                        modifier = Modifier
                            .size(80.dp)
                            .testTag("start_recording_button"),
                        shape = CircleShape,
                        colors = ButtonDefaults.buttonColors(
                            containerColor = MaterialTheme.colorScheme.primary
                        )
                    ) {
                        Icon(
                            imageVector = Icons.Default.FiberManualRecord,
                            contentDescription = "Start Recording",
                            tint = Color.White,
                            modifier = Modifier.size(32.dp)
                        )
                    }
                } else {
                    Button(
                        onClick = { viewModel.stopRecording() },
                        modifier = Modifier
                            .size(80.dp)
                            .testTag("stop_recording_button"),
                        shape = CircleShape,
                        colors = ButtonDefaults.buttonColors(
                            containerColor = MaterialTheme.colorScheme.error
                        )
                    ) {
                        Icon(
                            imageVector = Icons.Default.Stop,
                            contentDescription = "Stop Recording",
                            tint = Color.White,
                            modifier = Modifier.size(32.dp)
                        )
                    }
                }
            }

            // Recording Status
            if (isRecording) {
                Card(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(horizontal = 16.dp),
                    colors = CardDefaults.cardColors(
                        containerColor = MaterialTheme.colorScheme.surfaceVariant
                    )
                ) {
                    Column(
                        modifier = Modifier.padding(16.dp)
                    ) {
                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            horizontalArrangement = Arrangement.SpaceBetween
                        ) {
                            Text(
                                text = "Recording Time:",
                                style = MaterialTheme.typography.bodyMedium
                            )
                            Text(
                                text = formatTime(recordingTime),
                                style = MaterialTheme.typography.bodyMedium.copy(
                                    fontWeight = FontWeight.Bold
                                )
                            )
                        }
                        
                        Spacer(modifier = Modifier.height(8.dp))
                        
                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            horizontalArrangement = Arrangement.SpaceBetween
                        ) {
                            Text(
                                text = "Keypoints:",
                                style = MaterialTheme.typography.bodyMedium
                            )
                            Text(
                                text = "${keypoints.size}",
                                style = MaterialTheme.typography.bodyMedium.copy(
                                    fontWeight = FontWeight.Bold
                                )
                            )
                        }
                        
                        Spacer(modifier = Modifier.height(8.dp))
                        
                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            horizontalArrangement = Arrangement.SpaceBetween
                        ) {
                            Text(
                                text = "Tracking:",
                                style = MaterialTheme.typography.bodyMedium
                            )
                            Text(
                                text = "Stable", // Assuming stable tracking for now
                                style = MaterialTheme.typography.bodyMedium.copy(
                                    fontWeight = FontWeight.Bold,
                                    color = Color.Green
                                )
                            )
                        }
                        
                        Spacer(modifier = Modifier.height(8.dp))
                        
                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            horizontalArrangement = Arrangement.SpaceBetween
                        ) {
                            Text(
                                text = "AI Detection:",
                                style = MaterialTheme.typography.bodyMedium
                            )
                            Text(
                                text = if (isMediaPipeProcessing) "Processing..." else "${detectedObjects.size} objects",
                                style = MaterialTheme.typography.bodyMedium.copy(
                                    fontWeight = FontWeight.Bold,
                                    color = if (isMediaPipeProcessing) Color.Blue else Color.Green
                                )
                            )
                        }
                        
                        Spacer(modifier = Modifier.height(8.dp))
                        
                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            horizontalArrangement = Arrangement.SpaceBetween
                        ) {
                            Text(
                                text = "Navigation:",
                                style = MaterialTheme.typography.bodyMedium
                            )
                            Text(
                                text = navigationGuidance,
                                style = MaterialTheme.typography.bodyMedium.copy(
                                    fontWeight = FontWeight.Bold,
                                    color = if (navigationHazards.isNotEmpty()) Color.Red else Color.Green
                                )
                            )
                        }
                    }
                }
            }

            // Save Route Button
            if (!isRecording && recordedLocations.isNotEmpty()) {
                Button(
                    onClick = { showNameDialog = true },
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(16.dp)
                        .testTag("save_route_button"),
                    enabled = !isSaving
                ) {
                    if (isSaving) {
                        CircularProgressIndicator(
                            modifier = Modifier.size(20.dp),
                            color = MaterialTheme.colorScheme.onPrimary
                        )
                        Spacer(modifier = Modifier.width(8.dp))
                        Text("Saving...")
                    } else {
                        Icon(
                            imageVector = Icons.Default.Save,
                            contentDescription = "Save Route"
                        )
                        Spacer(modifier = Modifier.width(8.dp))
                        Text("Save Route")
                    }
                }
            }

            // Error Message
            viewModelErrorMessage?.let { error ->
                Card(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(16.dp),
                    colors = CardDefaults.cardColors(
                        containerColor = MaterialTheme.colorScheme.errorContainer
                    )
                ) {
                    Row(
                        modifier = Modifier.padding(16.dp),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Icon(
                            imageVector = Icons.Default.Error,
                            contentDescription = "Error",
                            tint = MaterialTheme.colorScheme.error
                        )
                        Spacer(modifier = Modifier.width(8.dp))
                        Text(
                            text = error,
                            style = MaterialTheme.typography.bodyMedium,
                            color = MaterialTheme.colorScheme.onErrorContainer
                        )
                        Spacer(modifier = Modifier.weight(1f))
                        IconButton(
                            onClick = { viewModel.clearError() }
                        ) {
                            Icon(
                                imageVector = Icons.Default.Close,
                                contentDescription = "Clear Error",
                                tint = MaterialTheme.colorScheme.error
                            )
                        }
                    }
                }
            }

            Spacer(modifier = Modifier.weight(1f))
        }

        // Save Route Dialog
        if (showNameDialog) {
            AlertDialog(
                onDismissRequest = { showNameDialog = false },
                title = { Text("Save Route") },
                text = {
                    Column {
                        OutlinedTextField(
                            value = routeName,
                            onValueChange = { routeName = it },
                            label = { Text("Route Name") },
                            modifier = Modifier.fillMaxWidth()
                        )
                        OutlinedTextField(
                            value = routeDescription,
                            onValueChange = { routeDescription = it },
                            label = { Text("Description") },
                            modifier = Modifier.fillMaxWidth()
                        )
                    }
                },
                confirmButton = {
                    Button(
                        onClick = {
                            if (routeName.isNotBlank()) {
                                viewModel.saveRoute(
                                    name = routeName,
                                    description = routeDescription,
                                    startLocation = recordedLocations.firstOrNull()?.let { "${it.latitude},${it.longitude}" } ?: "",
                                    endLocation = recordedLocations.lastOrNull()?.let { "${it.latitude},${it.longitude}" } ?: ""
                                )
                                showNameDialog = false
                            }
                        }
                    ) {
                        Text("Save")
                    }
                },
                dismissButton = {
                    TextButton(
                        onClick = { showNameDialog = false }
                    ) {
                        Text("Cancel")
                    }
                }
            )
        }

        // Device Compatibility Dialog
        if (showCompatibilityDialog) {
            AlertDialog(
                onDismissRequest = { showCompatibilityDialog = false },
                title = { 
                    Text(
                        text = "Device Compatibility Notice",
                        style = MaterialTheme.typography.headlineSmall,
                        fontWeight = FontWeight.Bold
                    )
                },
                text = {
                    Column {
                        Text(
                            text = "Your device doesn't support ARCore, but don't worry! The app will use an enhanced camera-based navigation system instead.",
                            style = MaterialTheme.typography.bodyMedium
                        )
                        Spacer(modifier = Modifier.height(16.dp))
                        Text(
                            text = "Features available in Camera Mode:",
                            style = MaterialTheme.typography.titleSmall,
                            fontWeight = FontWeight.Bold
                        )
                        Spacer(modifier = Modifier.height(8.dp))
                        Text("• Real-time object detection", style = MaterialTheme.typography.bodySmall)
                        Text("• Navigation hazard identification", style = MaterialTheme.typography.bodySmall)
                        Text("• Route recording and playback", style = MaterialTheme.typography.bodySmall)
                        Text("• Voice guidance", style = MaterialTheme.typography.bodySmall)
                        Text("• Indoor positioning", style = MaterialTheme.typography.bodySmall)
                        Spacer(modifier = Modifier.height(16.dp))
                        Card(
                            colors = CardDefaults.cardColors(
                                containerColor = MaterialTheme.colorScheme.primaryContainer
                            )
                        ) {
                            Column(
                                modifier = Modifier.padding(12.dp)
                            ) {
                                Text(
                                    text = "Device Info:",
                                    style = MaterialTheme.typography.titleSmall,
                                    fontWeight = FontWeight.Bold,
                                    color = MaterialTheme.colorScheme.onPrimaryContainer
                                )
                                val deviceInfo = deviceCompatibilityService.getDeviceInfo()
                                Text(
                                    text = "Model: ${deviceInfo["manufacturer"]} ${deviceInfo["model"]}",
                                    style = MaterialTheme.typography.bodySmall,
                                    color = MaterialTheme.colorScheme.onPrimaryContainer
                                )
                                Text(
                                    text = "Android: ${deviceInfo["android_version"]} (API ${deviceInfo["api_level"]})",
                                    style = MaterialTheme.typography.bodySmall,
                                    color = MaterialTheme.colorScheme.onPrimaryContainer
                                )
                            }
                        }
                    }
                },
                confirmButton = {
                    Button(
                        onClick = { showCompatibilityDialog = false }
                    ) {
                        Text("Continue with Camera Mode")
                    }
                },
                dismissButton = {
                    TextButton(
                        onClick = { 
                            showCompatibilityDialog = false
                            navController.navigateUp()
                        }
                    ) {
                        Text("Go Back")
                    }
                }
            )
        }

        // Snackbar for save success
        // Removed LaunchedEffect(viewModel.routeSaved) and any logic that checks or uses routeSaved
        // Removed snackbar for route save success
        SnackbarHost(hostState = snackbarHostState)
    }
}

private fun formatTime(seconds: Int): String {
    val minutes = seconds / 60
    val remainingSeconds = seconds % 60
    return String.format("%02d:%02d", minutes, remainingSeconds)
} 

// --- Helper functions --- 