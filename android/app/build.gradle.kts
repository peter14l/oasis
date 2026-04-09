plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

// ✅ Redirect build output to Flutter's expected location
buildDir = File(rootDir, "../build/app")

android {
    namespace = "com.example.morrow_v2"
    compileSdk = 36
    ndkVersion = "28.2.13676358"

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile> {
        compilerOptions {
            jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17)
            freeCompilerArgs.add("-Xjvm-default=all")
        }
    }

    defaultConfig {
        applicationId = "com.example.morrow_v2"
        minSdk = 24
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            // Read from environment variables if they exist (for CI)
            val envFile = System.getenv("RELEASE_STORE_FILE")
            val envStorePass = System.getenv("RELEASE_STORE_PASSWORD")
            val envKeyAlias = System.getenv("RELEASE_KEY_ALIAS")
            val envKeyPass = System.getenv("RELEASE_KEY_PASSWORD")

            if (!envFile.isNullOrEmpty()) {
                // Try relative to android/app first, then relative to repo root
                val appKeystore = file(envFile)
                storeFile = if (appKeystore.exists()) appKeystore else file("../${envFile}")
                storePassword = envStorePass
                keyAlias = envKeyAlias
                keyPassword = envKeyPass
                storeType = "PKCS12"
            }
        }
    }

    buildTypes {
        getByName("release") {
            isMinifyEnabled = false
            isShrinkResources = false
            
            // Use debug signing for CI (no keystore) or local builds
            val releaseStoreFile = System.getenv("RELEASE_STORE_FILE")
            val useDebugSigning = System.getenv("DEBUG_SIGNING") == "true" || releaseStoreFile.isNullOrEmpty()
            
            signingConfig = if (useDebugSigning) {
                signingConfigs.getByName("debug")
            } else {
                signingConfigs.getByName("release")
            }
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
        }
    }
}

configurations.all {
    resolutionStrategy {
        force("androidx.annotation:annotation-experimental:1.4.1")
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
