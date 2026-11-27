package io.github.farhad1618.dotmind.pattern

import io.github.farhad1618.dotmind.Scene

public object Patterns {
    private val byScene: Array<Pattern> = Array(Scene.entries.size) { index -> patternOf(Scene.entries[index]) }

    public operator fun get(scene: Scene): Pattern = byScene[scene.ordinal]

    private fun patternOf(scene: Scene): Pattern = when (scene) {
        Scene.BREATHE -> Breathe
        Scene.COMET -> Comet
        Scene.RADAR -> Radar
        Scene.GLOBE -> Globe
        Scene.CODE -> Code
        Scene.PAGES -> Pages
        Scene.STACK -> Stack
        Scene.PRISM -> Prism
        Scene.CIRCUIT -> Circuit
        Scene.TYPE -> Type
        Scene.HALO -> Halo
        Scene.CROSS -> Cross
        Scene.CHECK -> Check
        Scene.EMBER -> Ember
        Scene.ORBIT -> Orbit
        Scene.SERPENT -> Serpent
        Scene.PULSE -> Pulse
    }
}
