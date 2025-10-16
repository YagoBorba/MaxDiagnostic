import com.android.build.gradle.LibraryExtension
import org.gradle.api.JavaVersion
import org.jetbrains.kotlin.gradle.tasks.KotlinCompile
import java.io.File

allprojects {
    repositories {
        google()
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

subprojects {
    if (name == "internet_speed_test" || name == "flutter_internet_speed_test") {
        pluginManager.withPlugin("com.android.library") {
            extensions.configure(LibraryExtension::class.java) {
                if (namespace.isNullOrBlank()) {
                    namespace = "com.maxtdiagnostic.internet_speed_test"
                }
                sourceSets.getByName("main") {
                    manifest.srcFile(File(rootDir, "flutter_internet_speed_test_manifest/AndroidManifest.xml"))
                }
                // Inherit compileOptions and kotlinOptions from the root/app configuration
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
