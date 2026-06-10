import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// ── Release signing ──────────────────────────────────────────────────────────
// Priority order:
//   1. android/key.properties file (local dev)
//   2. Environment variables  KEY_ALIAS / KEY_PASSWORD / STORE_PASSWORD /
//      KEYSTORE_PATH (CI)
// Neither present → falls back to debug key (debug builds only; release builds
// will fail at signingConfig resolution, which is the correct behaviour).

val keyPropertiesFile = rootProject.file("key.properties")
val useKeyProperties = keyPropertiesFile.exists()
val useEnvVars = System.getenv("KEY_ALIAS") != null

val keyAlias: String by lazy {
    if (useKeyProperties) {
        Properties().apply { load(FileInputStream(keyPropertiesFile)) }
            .getProperty("keyAlias") ?: ""
    } else System.getenv("KEY_ALIAS") ?: ""
}
val keyPassword: String by lazy {
    if (useKeyProperties) {
        Properties().apply { load(FileInputStream(keyPropertiesFile)) }
            .getProperty("keyPassword") ?: ""
    } else System.getenv("KEY_PASSWORD") ?: ""
}
val storePassword: String by lazy {
    if (useKeyProperties) {
        Properties().apply { load(FileInputStream(keyPropertiesFile)) }
            .getProperty("storePassword") ?: ""
    } else System.getenv("STORE_PASSWORD") ?: ""
}
val storeFilePath: String by lazy {
    if (useKeyProperties) {
        Properties().apply { load(FileInputStream(keyPropertiesFile)) }
            .getProperty("storeFile") ?: "finpal-pro-release.jks"
    } else System.getenv("KEYSTORE_PATH") ?: "finpal-pro-release.jks"
}

val hasSigningConfig = useKeyProperties || useEnvVars

android {
    namespace = "com.finpalpro.finpal_pro"
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
        applicationId = "com.finpalpro.finpal_pro"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    if (hasSigningConfig) {
        signingConfigs {
            create("release") {
                storeFile = rootProject.file(storeFilePath)
                this.storePassword = storePassword
                this.keyAlias = keyAlias
                this.keyPassword = keyPassword
            }
        }
    }

    buildTypes {
        release {
            signingConfig = if (hasSigningConfig) {
                signingConfigs.getByName("release")
            } else {
                // No keystore available — uses debug key.
                // release builds without a keystore will not be distributable.
                signingConfigs.getByName("debug")
            }
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }
}

flutter {
    source = "../.."
}
