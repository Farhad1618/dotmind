package io.github.farhad1618.dotmind

public enum class Scene(public val id: String) {
    BREATHE("breathe"),
    COMET("comet"),
    RADAR("radar"),
    GLOBE("globe"),
    CODE("code"),
    PAGES("pages"),
    STACK("stack"),
    PRISM("prism"),
    CIRCUIT("circuit"),
    TYPE("type"),
    HALO("halo"),
    CROSS("cross"),
    CHECK("check"),
    EMBER("ember"),
    ORBIT("orbit"),
    SERPENT("serpent"),
    PULSE("pulse");

    public companion object {
        public fun fromId(id: String): Scene = entries.first { it.id == id }
    }
}
