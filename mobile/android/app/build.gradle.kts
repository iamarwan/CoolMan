plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// ─────────────────────────────────────────────────────────────────────────────
// Read --dart-define values (Flutter passes them to Gradle base64-encoded).
// API_BASE_URL decides whether plain-HTTP traffic is allowed:
//   http://  -> allowed (emulator, or your PC on the same Wi-Fi)
//   https:// -> blocked (production)
// ─────────────────────────────────────────────────────────────────────────────
val dartDefines: Map<String, String> =
    (project.findProperty("dart-defines") as String?)
        ?.split(",")
        ?.mapNotNull { encoded ->
            val decoded = runCatching {
                String(java.util.Base64.getDecoder().decode(encoded), Charsets.UTF_8)
            }.getOrNull() ?: return@mapNotNull null
            val eq = decoded.indexOf('=')
            if (eq > 0) decoded.substring(0, eq) to decoded.substring(eq + 1) else null
        }
        ?.toMap()
        ?: emptyMap()

val apiBaseUrl: String = dartDefines["API_BASE_URL"] ?: "http://10.0.2.2:8000"
val allowCleartext: Boolean = !apiBaseUrl.startsWith("https://")

android {
    namespace = "com.example.sabil"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.sabil"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        manifestPlaceholders["usesCleartextTraffic"] = allowCleartext.toString()
    }

    buildTypes {
        release {
            // TODO(before Play Store): create an upload key and use it here.
            // Debug keys are fine for installing the APK on your own phone.
            signingConfig = signingConfigs.getByName("debug")
            // Shrink code (R8) and strip unused resources -> smaller APK.
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
