import org.gradle.api.plugins.JavaPluginExtension

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// Forcer Java 17 pour tous les sous-projets (évite les warnings "source value 8 is obsolete")
subprojects {
    afterEvaluate {
        extensions.findByType<JavaPluginExtension>()?.run {
            sourceCompatibility = JavaVersion.VERSION_17
            targetCompatibility = JavaVersion.VERSION_17
        }
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
