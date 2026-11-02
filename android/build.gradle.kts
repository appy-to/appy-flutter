import groovy.json.JsonSlurper

group = "to.appy.sdk.flutter"
version = "1.0.0"

val nativeSdk = JsonSlurper().parse(file("../native-sdk.json")) as Map<*, *>
val nativeAndroid = nativeSdk["android"] as Map<*, *>
val nativeSdkDependency = "${nativeAndroid["coordinates"]}:${nativeSdk["version"]}"
val localNativeRepository = file("..").canonicalFile.resolve(nativeAndroid["localRepository"] as String)

buildscript {
    val kotlinVersion = "2.4.0"
    repositories {
        google()
        mavenCentral()
    }

    dependencies {
        classpath("com.android.tools.build:gradle:9.1.0")
        classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:$kotlinVersion")
    }
}

repositories {
    if (nativeSdk["source"] == "local") {
        if (!localNativeRepository.isDirectory) {
            throw GradleException(
                "native-sdk.json uses the local Appy Android SDK, but $localNativeRepository does not exist. " +
                    "Run ./gradlew :appy-sdk:publishReleasePublicationToLocalRepository in sdks/android, " +
                    "or set \"source\" to \"published\".",
            )
        }
        maven { url = uri(localNativeRepository) }
    }
    google()
    mavenCentral()
}

plugins {
    id("com.android.library")
}

android {
    namespace = "to.appy.sdk.flutter"

    compileSdk = 36

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    sourceSets {
        getByName("main") {
            java.srcDirs("src/main/kotlin")
        }
        getByName("test") {
            java.srcDirs("src/test/kotlin")
        }
    }

    defaultConfig {
        minSdk = 21
    }

    testOptions {
        unitTests {
            isIncludeAndroidResources = true
            isReturnDefaultValues = true
            all {
                it.outputs.upToDateWhen { false }

                it.testLogging {
                    events("passed", "skipped", "failed", "standardOut", "standardError")
                    showStandardStreams = true
                }
            }
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

dependencies {
    implementation(nativeSdkDependency)
    testImplementation("junit:junit:4.13.2")
    testImplementation("org.jetbrains.kotlin:kotlin-test")
    testImplementation("org.mockito:mockito-core:5.0.0")
}
