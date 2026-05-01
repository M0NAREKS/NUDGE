allprojects {
    repositories {
        google()
        mavenCentral()
        maven(url = "https://developer.huawei.com/repo/")
    }
}

fun Project.ensureAndroidNamespace() {
    val androidExtension = extensions.findByName("android") ?: return
    val getNamespace = androidExtension.javaClass.methods.firstOrNull { it.name == "getNamespace" } ?: return
    val setNamespace = androidExtension.javaClass.methods.firstOrNull { it.name == "setNamespace" } ?: return

    val existingNamespace = getNamespace.invoke(androidExtension) as? String
    if (!existingNamespace.isNullOrBlank()) {
        return
    }

    val manifestFile = file("src/main/AndroidManifest.xml")
    val manifestPackage = if (manifestFile.exists()) {
        Regex("package\\s*=\\s*\"([^\"]+)\"")
            .find(manifestFile.readText())
            ?.groupValues
            ?.getOrNull(1)
    } else {
        null
    }

    val fallbackNamespace =
        manifestPackage ?: "com.nudge.autofix.${name.replace('-', '_')}"
    setNamespace.invoke(androidExtension, fallbackNamespace)
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
    pluginManager.withPlugin("com.android.application") {
        ensureAndroidNamespace()
    }
    pluginManager.withPlugin("com.android.library") {
        ensureAndroidNamespace()
    }
    pluginManager.withPlugin("com.android.dynamic-feature") {
        ensureAndroidNamespace()
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
