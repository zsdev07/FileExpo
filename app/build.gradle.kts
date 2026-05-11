plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
}

android {
    namespace = "zx.offical.filexpo"
    compileSdk = 34

    defaultConfig {
        applicationId = "zx.offical.filexpo"
        minSdk = 24
        targetSdk = 34
        versionCode = 1
        versionName = "1.0"
    }

    buildFeatures {
        compose = true
    }
    composeOptions {
        kotlinCompilerExtensionVersion = "1.5.4"
    }
}

dependencies {
    implementation("androidx.core:core-ktx:1.12.0")
    implementation("androidx.lifecycle:lifecycle-runtime-ktx:2.7.0")
    implementation("androidx.lifecycle:lifecycle-viewmodel-compose:2.7.0")
    
    // Jetpack Compose & Material 3
    implementation("androidx.activity:activity-compose:1.8.2")
    implementation(platform("androidx.compose:compose-bom:2023.10.01"))
    implementation("androidx.compose.ui:ui")
    implementation("androidx.compose.material3:material3")
    implementation("androidx.compose.material:material-icons-extended")
    
    // DocumentFile API
    implementation("androidx.documentfile:documentfile:1.0.1")

    // Archiving & Compression Libraries
    implementation("net.lingala.zip4j:zip4j:2.11.5") // ZIP + AES
    implementation("org.apache.commons:commons-compress:1.24.0") // TAR, 7Z
    implementation("org.tukaani:xz:1.9") // 7Z support extension
    implementation("com.github.junrar:junrar:7.5.5") // RAR Multi-part Extraction
}