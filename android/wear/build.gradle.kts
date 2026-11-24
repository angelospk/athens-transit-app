// Wear OS app for Στάσεις: standalone for data (calls the backend itself), favourites synced from the
// phone over the Data Layer. Same applicationId and signing key as the phone (android/app).
plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("org.jetbrains.kotlin.plugin.compose")
    // Screenshot tests (JVM, Robolectric): ./gradlew :wear:recordRoborazziDebug
    id("io.github.takahirom.roborazzi")
}

// versionCode: the watch uses its own range, 2_000_000 + build, so it never collides with the phone's
// codes (pubspec build numbers, < 2_000_000) in the same Play listing. Bump wearBuild per release, or
// pass -P wearBuild=N.
val wearBuild = (project.findProperty("wearBuild") as String?)?.toIntOrNull() ?: 1

android {
    namespace = "gr.staseis.app.wear"
    compileSdk = 36

    defaultConfig {
        applicationId = "gr.staseis.app"
        minSdk = 30
        targetSdk = 36
        versionCode = 2_000_000 + wearBuild
        // Tracks the phone app's version (pubspec.yaml `version:` without the build number); bump together.
        versionName = "0.3.0"
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    buildFeatures {
        compose = true
        buildConfig = true
    }

    buildTypes {
        release {
            isMinifyEnabled = false
            // No signing config in the repo: the release is signed outside it (upload key on the build
            // machine / Play App Signing), with the same key as the phone so the Data Layer pairs them.
            // -P staging=true: same switch as the phone, so the dev watch app pairs with the dev phone app.
            if (project.findProperty("staging") == "true") {
                applicationIdSuffix = ".dev"
                versionNameSuffix = "-dev"
            }
        }
    }

    testOptions {
        unitTests.isReturnDefaultValues = true
        unitTests.isIncludeAndroidResources = true
        unitTests.all { it.maxHeapSize = "4g" }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

dependencies {
    val composeBom = platform("androidx.compose:compose-bom:2025.08.00")
    implementation(composeBom)
    implementation("androidx.activity:activity-compose:1.10.1")
    implementation("androidx.compose.ui:ui")
    implementation("androidx.compose.foundation:foundation")
    implementation("androidx.wear.compose:compose-material3:1.5.6")
    implementation("androidx.wear.compose:compose-foundation:1.5.6")
    implementation("androidx.wear.compose:compose-navigation:1.5.6")
    implementation("androidx.lifecycle:lifecycle-runtime-compose:2.9.2")
    implementation("androidx.lifecycle:lifecycle-viewmodel-compose:2.9.2")
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-android:1.10.2")
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-play-services:1.10.2")
    implementation("com.google.android.gms:play-services-wearable:19.0.0")
    implementation("com.google.android.gms:play-services-location:21.4.0")
    implementation("androidx.wear.tiles:tiles:1.5.0")
    implementation("androidx.wear.protolayout:protolayout:1.3.0")
    implementation("androidx.wear.protolayout:protolayout-expression:1.3.0")
    implementation("androidx.wear.protolayout:protolayout-material3:1.3.0")
    implementation("androidx.wear.watchface:watchface-complications-data-source-ktx:1.2.1")
    implementation("androidx.work:work-runtime-ktx:2.10.3")
    implementation("androidx.concurrent:concurrent-futures-ktx:1.2.0")

    testImplementation("junit:junit:4.13.2")
    testImplementation("org.json:json:20250517")
    testImplementation("org.robolectric:robolectric:4.16")
    testImplementation(composeBom)
    testImplementation("androidx.compose.ui:ui-test-junit4")
    // Hosts composables in the screenshot tests; debug builds only, and not exported (src/debug manifest).
    debugImplementation(composeBom)
    debugImplementation("androidx.compose.ui:ui-test-manifest")
    // Renders the tile in the screenshot tests; its resources must be merged, so debug only (not release).
    debugImplementation("androidx.wear.tiles:tiles-renderer:1.5.0")
    testImplementation("io.github.takahirom.roborazzi:roborazzi:1.79.0")
    testImplementation("io.github.takahirom.roborazzi:roborazzi-compose:1.79.0")
    testImplementation("io.github.takahirom.roborazzi:roborazzi-junit-rule:1.79.0")
}

roborazzi {
    outputDir.set(file("src/test/screenshots"))
}
