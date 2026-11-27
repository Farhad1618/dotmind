plugins {
    alias(libs.plugins.kotlin.jvm)
    `java-library`
    `maven-publish`
}

kotlin {
    jvmToolchain(17)
    explicitApi()
}

java {
    withSourcesJar()
}

dependencies {
    api(libs.kotlinx.coroutines.core)
    testImplementation(kotlin("test"))
    testImplementation(libs.kotlinx.serialization.json)
}

tasks.test {
    useJUnitPlatform()
    systemProperty("dotmind.golden", rootProject.file("../../spec/golden.json").absolutePath)
}

publishing {
    publications {
        create<MavenPublication>("maven") {
            artifactId = "dotmind-core"
            from(components["java"])
        }
    }
}
