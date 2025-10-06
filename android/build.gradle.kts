buildscript {
    val kotlin_version by extra("2.1.0")
    repositories {
        google()
        mavenCentral()
    }

    dependencies {
        classpath("com.android.tools.build:gradle:8.1.4")
        classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:$kotlin_version")
        classpath("com.google.gms:google-services:4.4.0")
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

subprojects {
    afterEvaluate {
        // Fix Vosk Flutter plugin issues
        if (project.name == "vosk_flutter") {
            // Fix AndroidManifest.xml by removing package attribute
            val manifestFile = file("src/main/AndroidManifest.xml")
            if (manifestFile.exists()) {
                val content = manifestFile.readText()
                if (content.contains("""package="org.vosk.vosk_flutter"""")) {
                    val fixedContent = content.replace("""package="org.vosk.vosk_flutter"""", "")
                        .replace(Regex("""\s+"""), " ")
                        .replace(Regex("""\s+>"""), ">")
                    manifestFile.writeText(fixedContent)
                    println("Fixed AndroidManifest.xml for vosk_flutter plugin")
                }
            }
        }
        
        // Fix permission_handler_android v1 embedding compatibility issues
        if (project.name == "permission_handler_android") {
            // Ensure proper namespace and compatibility
            extensions.findByName("android")?.let { android ->
                if (android is com.android.build.gradle.BaseExtension) {
                    android.namespace = "com.baseflow.permissionhandler"
                    
                    // Force compatibility with newer AGP
                    android.compileSdkVersion(34)
                    android.defaultConfig {
                        minSdk = 21
                        targetSdk = 34
                    }
                }
            }
        }
        
        // Make vosk_flutter independent of other plugins
        if (project.name == "vosk_flutter") {
            // Isolate vosk_flutter dependencies
            configurations.all {
                resolutionStrategy {
                    force("com.baseflow:permission_handler_android:12.0.0")
                    force("androidx.core:core:1.12.0")
                    force("androidx.appcompat:appcompat:1.6.1")
                }
            }
        }
        
        // Force all Java compilation to use Java 11
        tasks.withType<JavaCompile>().configureEach {
            sourceCompatibility = JavaVersion.VERSION_11.toString()
            targetCompatibility = JavaVersion.VERSION_11.toString()
        }
        
        // Force all Kotlin compilation to use JVM target 11
        tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>().configureEach {
            kotlinOptions {
                jvmTarget = "11"
                languageVersion = "1.8"
                apiVersion = "1.8"
                freeCompilerArgs = listOf("-Xjvm-default=all")
            }
        }
        
        // Apply to Android plugin configurations if present
        extensions.findByName("android")?.let { android ->
            if (android is com.android.build.gradle.BaseExtension) {
                android.compileOptions {
                    sourceCompatibility = JavaVersion.VERSION_11
                    targetCompatibility = JavaVersion.VERSION_11
                }
                
                // Fix namespace issue for vosk_flutter plugin
                if (project.name == "vosk_flutter") {
                    android.namespace = "org.vosk.libvosk"
                }
            }
        }
    }
}

rootProject.layout.buildDirectory.set(file("../build"))
subprojects {
    project.layout.buildDirectory.set(file("${rootProject.layout.buildDirectory.get()}/${project.name}"))
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register("clean", Delete::class) {
    delete(rootProject.layout.buildDirectory)
}