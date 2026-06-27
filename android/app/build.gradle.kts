plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    id("com.google.firebase.crashlytics")
    // END: FlutterFire Configuration
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.lunarae.mobile"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "28.0.12674087"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.lunarae.mobile"
        minSdk = flutter.minSdkVersion
        targetSdk = 35
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            // Check for Codemagic's default UI variables first
            val cmKeystorePath = System.getenv("CM_KEYSTORE_PATH")
            val localKeystorePath = System.getenv("KEYSTORE_PATH")

            if (cmKeystorePath != null && cmKeystorePath.isNotEmpty()) {
                // Building on Codemagic using UI code signing
                storeFile = file(cmKeystorePath)
                storePassword = System.getenv("CM_KEYSTORE_PASSWORD")
                keyAlias = System.getenv("CM_KEY_ALIAS")
                keyPassword = System.getenv("CM_KEY_PASSWORD")
            } else if (localKeystorePath != null && localKeystorePath.isNotEmpty()) {
                // Fallback for your custom/local environment variables
                storeFile = file(localKeystorePath)
                storePassword = System.getenv("KEYSTORE_PASSWORD")
                keyAlias = System.getenv("KEY_ALIAS")
                keyPassword = System.getenv("KEY_PASSWORD")
            } else {
                // Fallback for building locally without any environment variables
                storeFile = file("../my-release-key.jks")
                storePassword = "your_local_password_here"
                keyAlias = "my-key-alias"
                keyPassword = "your_local_password_here"
            }
        }
    }


    buildTypes {
        getByName("debug") {
            applicationIdSuffix = ".debug"
        }
        getByName("release") {
            signingConfig = signingConfigs.findByName("release")
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }
}

flutter {
    source = "../.."
}
