plugins {
    alias(libs.plugins.android.application) apply false
    alias(libs.plugins.android.library) apply false
    alias(libs.plugins.kotlin.jvm) apply false
    alias(libs.plugins.kotlin.android) apply false
    alias(libs.plugins.kotlin.serialization) apply false
    alias(libs.plugins.kotlin.compose) apply false
}

subprojects {
    group = "io.github.farhad1618"
    version = "0.2.0"

    plugins.withId("maven-publish") {
        extensions.configure<PublishingExtension> {
            publications.withType<MavenPublication>().configureEach {
                pom {
                    name.set(provider { artifactId })
                    description.set("Dot-matrix status indicators that follow an AI model's stream.")
                    url.set("https://github.com/Farhad1618/dotmind")
                    licenses {
                        license {
                            name.set("MIT")
                            url.set("https://opensource.org/licenses/MIT")
                        }
                    }
                    developers {
                        developer {
                            id.set("farhad1618")
                        }
                    }
                    scm {
                        url.set("https://github.com/Farhad1618/dotmind")
                        connection.set("scm:git:https://github.com/Farhad1618/dotmind.git")
                    }
                }
            }
        }
    }
}
