plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

android {
    namespace = "com.example.whisptask"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    defaultConfig {
        applicationId = "com.example.whisptask"
        
        // Use property assignment syntax for Kotlin DSL with Flutter properties
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        // Force notification icon
        manifestPlaceholders["notificationIcon"] = "@drawable/ic_notification"
        
        // RevenueCat App ID for Google Play
        manifestPlaceholders["revenueCatAppId"] = "app6d8de76b03"
    }

    signingConfigs {
        create("release") {
            // For production, you should use proper keystore
            // This is a placeholder - replace with your actual keystore
            storeFile = file("upload-keystore.jks")
            storePassword = System.getenv("KEYSTORE_PASSWORD") ?: "android"
            keyAlias = System.getenv("KEY_ALIAS") ?: "upload"
            keyPassword = System.getenv("KEY_PASSWORD") ?: "android"
        }
    }

    buildTypes {
        release {
            // Use release signing config when available, fallback to debug for development
            signingConfig = if (file("upload-keystore.jks").exists()) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
        // Enable core library desugaring
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = "11"
    }

    // Add compiler arguments to show deprecation details
    tasks.withType<JavaCompile> {
        options.compilerArgs.add("-Xlint:deprecation")
    }

}

flutter {
    source = "../.."
}

dependencies {
    // Core library desugaring
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
    
    // Import the Firebase BoM (Latest stable version)
    implementation(platform("com.google.firebase:firebase-bom:33.5.1"))
    
    // Firebase Analytics
    implementation("com.google.firebase:firebase-analytics")
    
    // Add other Firebase dependencies as needed
    implementation("com.google.firebase:firebase-auth")
    implementation("com.google.firebase:firebase-firestore")
    implementation("com.google.firebase:firebase-messaging")
    
    // Google Play Services Auth for Google Sign-In
    implementation("com.google.android.gms:play-services-auth:21.0.0")
}