package io.github.farhad1618.dotmind

internal class RenderLayer(
    var scene: Scene,
    var color: Rgb,
    var time: Double = 0.0,
    var origin: Double = 0.0,
) {
    fun reset(scene: Scene, color: Rgb, origin: Double) {
        this.scene = scene
        this.color = color
        this.time = 0.0
        this.origin = origin
    }
}
