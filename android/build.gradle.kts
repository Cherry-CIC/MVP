allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
    // section added to fix current stripe error on build:
    //
    // Execution failed for task ':stripe_android:checkDebugAarMetadata'.
    // :stripe_android is currently compiled against android-35.
    project.configurations.all {
        resolutionStrategy {
            // Force these to versions that work with API 35
            force( "androidx.browser:browser:1.8.0")
            force( "androidx.activity:activity:1.9.3")
            force( "androidx.activity:activity-ktx:1.9.3")
            force( "androidx.activity:activity-compose:1.9.3")
            force( "androidx.core:core:1.13.1")
            force( "androidx.core:core-ktx:1.13.1")
            force( "androidx.lifecycle:lifecycle-runtime-ktx:2.8.7")
        }
    }
    // end section
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
