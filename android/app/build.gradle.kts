plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

android {
    namespace = "com.app.lost_and_found"
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_21
        targetCompatibility = JavaVersion.VERSION_21
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = "21"
    }

    defaultConfig {
        applicationId = "com.app.lost_and_found"
        minSdk = flutter.minSdkVersion
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        multiDexEnabled = true
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

dependencies {
    // Firebase BOM
    implementation(platform("com.google.firebase:firebase-bom:34.6.0"))
    implementation("com.google.firebase:firebase-analytics")
    implementation("com.google.firebase:firebase-auth")
    implementation("com.google.firebase:firebase-firestore")
    implementation("com.google.firebase:firebase-messaging")
    
    // Google Sign-In
    implementation("com.google.android.gms:play-services-auth:21.2.0")
    
    // Kotlin
    implementation("org.jetbrains.kotlin:kotlin-stdlib-jdk7:1.9.10")
    
    // Desugaring
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
    
    // MultiDex
    implementation("androidx.multidex:multidex:2.0.1")
}

flutter {
    source = "../.."
}
