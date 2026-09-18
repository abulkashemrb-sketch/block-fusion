pluginManagement {
    val flutterSdkPath =
        run {
            val properties = java.util.Properties()
            file("local.properties").inputStream().use { properties.load(it) }
            val flutterSdkPath = properties.getProperty("flutter.sdk")
            require(flutterSdkPath != null) { "flutter.sdk not set in local.properties" }
            flutterSdkPath
        }

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        // Google's mirror also carries copies of third-party artifacts
        // (Kotlin's, for one). It is consulted first, so a 502 from it
        // fails the build outright instead of falling through to the
        // repository those artifacts actually live in. Restricting it to
        // the groups it is authoritative for sends everything else
        // straight to Maven Central. The dots are left unescaped on
        // purpose: a Kotlin string literal rejects a lone backslash-dot,
        // and "any character" here matches nothing we do not want.
        google {
            content {
                includeGroupByRegex("com.android.*")
                includeGroupByRegex("com.google.*")
                includeGroupByRegex("androidx.*")
            }
        }
        mavenCentral()
        gradlePluginPortal()
    }
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    id("com.android.application") version "9.1.0" apply false
    id("org.jetbrains.kotlin.android") version "2.4.0" apply false
}

include(":app")
