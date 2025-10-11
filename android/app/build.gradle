plugins {
    id("com.android.application")
    id("kotlin-android")

}

// Add this instead:
apply from: "$flutterRoot/packages/flutter_tools/gradle/flutter.gradle"
android {
    namespace = "com.example.nav_aif_fyp"
    compileSdk = 33  // Change from 34 to 33 for better compatibility
    
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_1_8
        targetCompatibility = JavaVersion.VERSION_1_8
    }

    kotlinOptions {
        jvmTarget = "1.8"
    }

    buildFeatures {
        buildConfig = true
    }

    defaultConfig {
        applicationId = "com.example.nav_aif_fyp"
        minSdk = flutter.minSdkVersion
        targetSdk = 33
        versionCode = 1
        versionName = "1.0"
    }

    buildTypes {
        release {
            isMinifyEnabled = false
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}
