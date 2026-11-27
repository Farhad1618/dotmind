package io.github.farhad1618.dotmind.compose

import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.withFrameNanos

@Composable
internal fun FrameLoop(host: IndicatorHost, running: Boolean) {
    LaunchedEffect(host, running) {
        if (!running) return@LaunchedEffect
        val step = FrameStep(host)
        while (true) withFrameNanos(step)
    }
}

private class FrameStep(private val host: IndicatorHost) : (Long) -> Unit {
    private var last = 0L

    override fun invoke(now: Long) {
        val dt = if (last == 0L) 0.0 else (now - last) / NANOS_PER_SECOND
        last = now
        host.tick(dt)
    }

    private companion object {
        const val NANOS_PER_SECOND = 1_000_000_000.0
    }
}
