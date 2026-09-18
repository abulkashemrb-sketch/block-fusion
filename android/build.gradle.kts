allprojects {
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
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
