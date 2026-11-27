package io.github.farhad1618.dotmind

public object SceneColors {
    private val colors: Array<Rgb> = Array(Scene.entries.size) { index -> colorOf(Scene.entries[index]) }

    public operator fun get(scene: Scene): Rgb = colors[scene.ordinal]

    private fun colorOf(scene: Scene): Rgb = when (scene) {
        Scene.BREATHE -> Rgb(160, 160, 172)
        Scene.COMET -> Rgb(143, 125, 255)
        Scene.RADAR -> Rgb(61, 123, 255)
        Scene.GLOBE -> Rgb(74, 168, 255)
        Scene.CODE -> Rgb(255, 162, 31)
        Scene.PAGES -> Rgb(56, 210, 190)
        Scene.STACK -> Rgb(255, 122, 26)
        Scene.PRISM -> Rgb(255, 190, 60)
        Scene.CIRCUIT -> Rgb(74, 168, 255)
        Scene.TYPE -> Rgb(228, 228, 236)
        Scene.HALO -> Rgb(255, 176, 32)
        Scene.CROSS -> Rgb(255, 74, 62)
        Scene.CHECK -> Rgb(70, 220, 130)
        Scene.EMBER -> Rgb(255, 74, 42)
        Scene.ORBIT -> Rgb(61, 123, 255)
        Scene.SERPENT -> Rgb(154, 107, 255)
        Scene.PULSE -> Rgb(255, 122, 26)
    }
}
