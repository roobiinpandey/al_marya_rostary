plugins {
    id("com.android.application")
    id("kotlin-android")
    // id("com.google.gms.google-services") // Temporarily disabled for Gradle verification
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.qahwat.alemarat"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.qahwat.alemarat"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        
        // Add multiDex support for large apps
        multiDexEnabled = true
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
            
            // Enable code shrinking and obfuscation for release builds
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
        debug {
            // Debug configuration
            isDebuggable = true
        }
    }
    
    // Add packaging options to avoid conflicts
    buildFeatures {
        buildConfig = true
    }
    
    packaging {
        resources {
            excludes += listOf(
                "META-INF/DEPENDENCIES",
                "META-INF/LICENSE",
                "META-INF/LICENSE.txt",
                "META-INF/license.txt",
                "META-INF/NOTICE",
                "META-INF/NOTICE.txt",
                "META-INF/notice.txt",
                "META-INF/ASL2.0"
            )
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // Add MultiDex support
    implementation("androidx.multidex:multidex:2.0.1")
    
    // Firebase and Google Sign-In dependencies - temporarily commented for Gradle verification
    // implementation(platform("com.google.firebase:firebase-bom:33.7.0"))
    // implementation("com.google.firebase:firebase-analytics-ktx")
    // implementation("com.google.firebase:firebase-auth-ktx")
    // implementation("com.google.android.gms:play-services-auth:21.3.0")
}
