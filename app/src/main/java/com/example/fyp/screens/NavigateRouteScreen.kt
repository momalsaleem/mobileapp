package com.example.fyp.screens

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.runtime.collectAsState
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.hilt.navigation.compose.hiltViewModel
import com.example.fyp.viewmodel.RouteNavigationViewModel
import com.example.fyp.service.ClewNavigationService

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun NavigateRouteScreen(
    navController: androidx.navigation.NavController,
    viewModel: RouteNavigationViewModel = hiltViewModel()
) {
    LocationPermissionRequest()
    val routes by viewModel.routes.collectAsState()
    val selectedRoute by viewModel.selectedRoute.collectAsState()
    val isNavigating by viewModel.isNavigating.collectAsState()
    val currentInstruction by viewModel.currentInstruction.collectAsState()
    val navigationProgress by viewModel.navigationProgress.collectAsState()
    val distanceToNext by viewModel.distanceToNext.collectAsState()
    val errorMessage by viewModel.errorMessage.collectAsState()
    
    // Clew-specific navigation states
    val navigationStatus by viewModel.navigationStatus.collectAsState()
    val currentKeypoint by viewModel.currentKeypoint.collectAsState()
    val nextKeypoint by viewModel.nextKeypoint.collectAsState()

    Scaffold(
        topBar = {
            TopAppBar(
                title = {
                    Text(
                        text = "Navigate Route",
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
            // Route Selection
            if (!isNavigating) {
                Card(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(16.dp)
                ) {
                    Column(
                        modifier = Modifier.padding(16.dp)
                    ) {
                        Text(
                            text = "Select a Route",
                            style = MaterialTheme.typography.headlineSmall,
                            fontWeight = FontWeight.Bold
                        )
                        
                        Spacer(modifier = Modifier.height(16.dp))
                        
                        LazyColumn {
                            items(routes) { route ->
                                Card(
                                    modifier = Modifier
                                        .fillMaxWidth()
                                        .padding(vertical = 4.dp)
                                        .testTag("route_item_${route.id}"),
                                    onClick = { viewModel.selectRoute(route) }
                                ) {
                                    Column(
                                        modifier = Modifier.padding(16.dp)
                                    ) {
                                        Text(
                                            text = route.name,
                                            style = MaterialTheme.typography.titleMedium,
                                            fontWeight = FontWeight.Bold
                                        )
                                        Text(
                                            text = route.description,
                                            style = MaterialTheme.typography.bodyMedium,
                                            color = MaterialTheme.colorScheme.onSurfaceVariant
                                        )
                                        Text(
                                            text = "Keypoints: ${route.locations.count { it.isKeypoint }}",
                                            style = MaterialTheme.typography.bodySmall,
                                            color = MaterialTheme.colorScheme.primary
                                        )
                                    }
                                }
                            }
                        }
                        
                        if (selectedRoute != null) {
                            Spacer(modifier = Modifier.height(16.dp))
                            Button(
                                onClick = { viewModel.startNavigation() },
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .testTag("start_navigation_button")
                            ) {
                                Icon(
                                    imageVector = Icons.Default.Navigation,
                                    contentDescription = "Start Navigation"
                                )
                                Spacer(modifier = Modifier.width(8.dp))
                                Text("Start Navigation")
                            }
                        }
                    }
                }
            }

            // Navigation Interface (Clew-style)
            if (isNavigating) {
                // Main Navigation Display
                Card(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(16.dp),
                    colors = CardDefaults.cardColors(
                        containerColor = when (navigationStatus) {
                            ClewNavigationService.NavigationStatus.APPROACHING -> Color.Yellow.copy(alpha = 0.1f)
                            ClewNavigationService.NavigationStatus.MOVING_TO_NEXT -> Color.Green.copy(alpha = 0.1f)
                            ClewNavigationService.NavigationStatus.ARRIVED -> Color.Blue.copy(alpha = 0.1f)
                            else -> MaterialTheme.colorScheme.surfaceVariant
                        }
                    )
                ) {
                    Column(
                        modifier = Modifier.padding(24.dp),
                        horizontalAlignment = Alignment.CenterHorizontally
                    ) {
                        // Navigation Status Icon
                        Icon(
                            imageVector = when (navigationStatus) {
                                ClewNavigationService.NavigationStatus.STARTING -> Icons.Default.PlayArrow
                                ClewNavigationService.NavigationStatus.MOVING -> Icons.Default.Navigation
                                ClewNavigationService.NavigationStatus.APPROACHING -> Icons.Default.Warning
                                ClewNavigationService.NavigationStatus.MOVING_TO_NEXT -> Icons.Default.CheckCircle
                                ClewNavigationService.NavigationStatus.ARRIVED -> Icons.Default.Flag
                                else -> Icons.Default.Navigation
                            },
                            contentDescription = "Navigation Status",
                            modifier = Modifier.size(48.dp),
                            tint = when (navigationStatus) {
                                ClewNavigationService.NavigationStatus.APPROACHING -> Color(0xFFFFA500)
                                ClewNavigationService.NavigationStatus.MOVING_TO_NEXT -> Color.Green
                                ClewNavigationService.NavigationStatus.ARRIVED -> Color.Blue
                                else -> MaterialTheme.colorScheme.primary
                            }
                        )
                        
                        Spacer(modifier = Modifier.height(16.dp))
                        
                        // Current Instruction (Clew's main instruction)
                        Text(
                            text = currentInstruction,
                            style = MaterialTheme.typography.headlineSmall,
                            fontWeight = FontWeight.Bold,
                            textAlign = TextAlign.Center,
                            modifier = Modifier.fillMaxWidth()
                        )
                        
                        Spacer(modifier = Modifier.height(16.dp))
                        
                        // Distance to Next Keypoint
                        Card(
                            modifier = Modifier.fillMaxWidth(),
                            colors = CardDefaults.cardColors(
                                containerColor = MaterialTheme.colorScheme.primaryContainer
                            )
                        ) {
                            Column(
                                modifier = Modifier.padding(16.dp),
                                horizontalAlignment = Alignment.CenterHorizontally
                            ) {
                                Text(
                                    text = "Distance to Next",
                                    style = MaterialTheme.typography.bodyMedium,
                                    color = MaterialTheme.colorScheme.onPrimaryContainer
                                )
                                Text(
                                    text = viewModel.getDistanceToNextFormatted(),
                                    style = MaterialTheme.typography.headlineMedium,
                                    fontWeight = FontWeight.Bold,
                                    color = MaterialTheme.colorScheme.onPrimaryContainer
                                )
                            }
                        }
                        
                        Spacer(modifier = Modifier.height(16.dp))
                        
                        // Progress Bar
                        LinearProgressIndicator(
                            progress = navigationProgress / 100f,
                            modifier = Modifier
                                .fillMaxWidth()
                                .height(8.dp)
                                .testTag("navigation_progress"),
                            color = MaterialTheme.colorScheme.primary,
                            trackColor = MaterialTheme.colorScheme.surfaceVariant
                        )
                        
                        Spacer(modifier = Modifier.height(8.dp))
                        
                        Text(
                            text = "${viewModel.getNavigationProgressPercentage()}% Complete",
                            style = MaterialTheme.typography.bodyMedium,
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                        
                        Spacer(modifier = Modifier.height(16.dp))
                        
                        // Keypoint Information
                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            horizontalArrangement = Arrangement.SpaceBetween
                        ) {
                            Column(
                                horizontalAlignment = Alignment.Start
                            ) {
                                Text(
                                    text = "Current Keypoint",
                                    style = MaterialTheme.typography.bodySmall,
                                    color = MaterialTheme.colorScheme.onSurfaceVariant
                                )
                                Text(
                                    text = viewModel.getCurrentKeypointType(),
                                    style = MaterialTheme.typography.bodyMedium,
                                    fontWeight = FontWeight.Bold
                                )
                            }
                            
                            Column(
                                horizontalAlignment = Alignment.End
                            ) {
                                Text(
                                    text = "Next Keypoint",
                                    style = MaterialTheme.typography.bodySmall,
                                    color = MaterialTheme.colorScheme.onSurfaceVariant
                                )
                                Text(
                                    text = viewModel.getNextKeypointType(),
                                    style = MaterialTheme.typography.bodyMedium,
                                    fontWeight = FontWeight.Bold
                                )
                            }
                        }
                        
                        Spacer(modifier = Modifier.height(8.dp))
                        
                        // Step Counter
                        Text(
                            text = "Step ${viewModel.getCurrentStep() + 1} of ${viewModel.getTotalSteps()}",
                            style = MaterialTheme.typography.bodyMedium,
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                    }
                }
                
                // Navigation Controls
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(16.dp),
                    horizontalArrangement = Arrangement.SpaceEvenly
                ) {
                    Button(
                        onClick = { viewModel.stopNavigation() },
                        modifier = Modifier.testTag("stop_navigation_button"),
                        colors = ButtonDefaults.buttonColors(
                            containerColor = MaterialTheme.colorScheme.error
                        )
                    ) {
                        Icon(
                            imageVector = Icons.Default.Stop,
                            contentDescription = "Stop Navigation"
                        )
                        Spacer(modifier = Modifier.width(8.dp))
                        Text("Stop")
                    }
                    
                    if (viewModel.hasArrived()) {
                        Button(
                            onClick = { navController.navigateUp() },
                            modifier = Modifier.testTag("finish_navigation_button")
                        ) {
                            Icon(
                                imageVector = Icons.Default.Check,
                                contentDescription = "Finish Navigation"
                            )
                            Spacer(modifier = Modifier.width(8.dp))
                            Text("Finish")
                        }
                    }
                }
            }

            // Error Message
            errorMessage?.let { error ->
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
    }
} 