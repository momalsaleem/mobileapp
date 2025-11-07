package com.example.fyp.navigation

import androidx.compose.runtime.Composable
import androidx.navigation.NavHostController
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import com.example.fyp.screens.HomeScreen
import com.example.fyp.screens.RecordRouteScreen
import com.example.fyp.screens.NavigateRouteScreen
import com.example.fyp.screens.SettingsScreen
import com.example.fyp.screens.RouteListScreen
import com.example.fyp.screens.AITrainingScreen

sealed class Screen(val route: String) {
    object Home : Screen("home")
    object RecordRoute : Screen("record_route")
    object NavigateRoute : Screen("navigate_route")
    object RouteList : Screen("route_list")
    object Settings : Screen("settings")
    object AITraining : Screen("ai_training")
}

@Composable
fun AppNavigation(navController: NavHostController) {
    NavHost(
        navController = navController,
        startDestination = Screen.Home.route
    ) {
        composable(Screen.Home.route) {
            HomeScreen(navController)
        }
        composable(Screen.RecordRoute.route) {
            RecordRouteScreen(navController)
        }
        composable(Screen.NavigateRoute.route) {
            NavigateRouteScreen(navController)
        }
        composable(Screen.RouteList.route) {
            RouteListScreen(navController)
        }
        composable(Screen.Settings.route) {
            SettingsScreen(navController)
        }
        composable(Screen.AITraining.route) {
            AITrainingScreen(navController)
        }
    }
} 