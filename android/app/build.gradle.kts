plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

// ✅ Redirect build output to Flutter's expected location
buildDir = File(rootDir, "../build/app")

android {
    namespace = "com.oasis.app"
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
        applicationId = "com.oasis.app" // Production: com.oasis.app
        minSdk = 24
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        getByName("debug") {
            // Debug build: com.oasis.app.debug
            applicationIdSuffix = ".debug"
        }
        getByName("release") {
            // Release build: com.oasis.app
            
            isMinifyEnabled = true
            isShrinkResources = false
            
            // Use release signing config for local builds
            // CI workflow signs with r0adkll/sign-android-release action
            val hasKeystore = !System.getenv("RELEASE_STORE_FILE").isNullOrEmpty()
            signingConfig = if (hasKeystore) {
                signingConfigs.getByName("release")
            } else {
                // For CI: build unsigned, sign later with action
                // For local: needs keystore env vars or use debug
                signingConfigs.getByName("debug")
            }
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
        }
    }

    signingConfigs {
        create("release") {
            // Used for local release builds
            // CI uses r0adkll/sign-android-release action instead
            val envStoreFile = System.getenv("RELEASE_STORE_FILE")
            val envStorePass = System.getenv("KEYSTORE_PASSWORD")
            val envKeyAlias = System.getenv("KEY_ALIAS")
            val envKeyPass = System.getenv("KEY_PASSWORD")

            if (!envStoreFile.isNullOrEmpty()) {
                storeFile = file(envStoreFile)
                storePassword = envStorePass
                keyAlias = envKeyAlias
                keyPassword = envKeyPass
                storeType = "PKCS12"
            }
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