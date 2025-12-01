plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

import java.util.Properties
import java.io.FileInputStream

// Load signing properties if present at the project root (android/key.properties)
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.example.nav_aif_fyp"
    // Set application id/namespace for the released app
    namespace = "com.navai.app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // Application ID - update to your package name
        applicationId = "com.navai.app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // Use release signing config when key properties are provided
            try {
                signingConfig = signingConfigs.getByName("release")
            } catch (e: Exception) {
                // Fallback to debug signing if release config isn't configured
                signingConfig = signingConfigs.getByName("debug")
            }
        }
    }

    // Configure release signing only if key.properties exists and the keystore file is present
    if (keystorePropertiesFile.exists()) {
        val storeFileProp = keystoreProperties.getProperty("storeFile")
        if (storeFileProp != null && file(storeFileProp).exists()) {
            signingConfigs {
                create("release") {
                    // keystoreProperties keys: storeFile, storePassword, keyAlias, keyPassword
                    storeFile = file(storeFileProp)
                    storePassword = keystoreProperties.getProperty("storePassword")
                    keyAlias = keystoreProperties.getProperty("keyAlias")
                    keyPassword = keystoreProperties.getProperty("keyPassword")
                }
            }
        }
    }
}

flutter {
    source = "../.."
}
