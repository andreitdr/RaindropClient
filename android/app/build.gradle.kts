import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Release signing. `android/key.properties` is deliberately not in the repository — it names a
// keystore and holds its passwords. Without it (a fresh clone, or CI) the release build falls
// back to the debug keys, so `flutter build apk --release` still works for testing; such a build
// just cannot be published. See docs/mobile.md.
val keystoreProperties = Properties().apply {
    val file = rootProject.file("key.properties")
    if (file.exists()) file.inputStream().use { load(it) }
}
val hasReleaseKeystore = keystoreProperties.getProperty("storeFile") != null

android {
    namespace = "com.raindrop.raindrop_client"
    // Pinned rather than `flutter.compileSdkVersion` (36 in this Flutter): one
    // plugin's AAR metadata requires its consumers to compile against 37, and
    // `checkDebugAarMetadata` fails the whole build if they do not.
    // flutter_secure_storage is the one today; raise this when another asks.
    compileSdk = 37
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.raindrop.raindrop_client"
        // Android 8.0. Above Flutter's own default (24) on purpose: the call's foreground
        // service needs `startForegroundService` and notification channels, both API 26, and
        // guarding those for Android 7 would add branches for a version no longer in use.
        // The plugins' own floors are lower (webrtc/livekit 21, secure storage 24).
        minSdk = 26
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        ndk {
            // The ABIs the Rust crypto core is cross-compiled for too (cargokit reads this).
            // No 32-bit x86: no current device or emulator image needs it, and every ABI
            // listed is another full Rust build.
            abiFilters += listOf("arm64-v8a", "armeabi-v7a", "x86_64")
        }
    }

    signingConfigs {
        if (hasReleaseKeystore) {
            create("release") {
                storeFile = rootProject.file(keystoreProperties.getProperty("storeFile"))
                storePassword = keystoreProperties.getProperty("storePassword")
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
            }
        }
    }

    buildTypes {
        release {
            signingConfig = if (hasReleaseKeystore) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
        }
    }
}

dependencies {
    // NotificationCompat, for the ongoing-call notification (CallForegroundService). The Flutter
    // embedding pulls androidx.core in already; naming it here means this app's own code does not
    // depend on that staying true.
    implementation("androidx.core:core-ktx:1.15.0")
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
