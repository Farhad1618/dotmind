package io.github.farhad1618.dotmind.example

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ExperimentalLayoutApi
import androidx.compose.foundation.layout.FlowRow
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.WindowInsetsSides
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.only
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.safeDrawing
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.layout.windowInsetsPadding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.BasicText
import androidx.compose.foundation.verticalScroll
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateListOf
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.SpanStyle
import androidx.compose.ui.text.buildAnnotatedString
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.withStyle
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import io.github.farhad1618.dotmind.Activity
import io.github.farhad1618.dotmind.ActivityTracker
import io.github.farhad1618.dotmind.Phase
import io.github.farhad1618.dotmind.Scene
import io.github.farhad1618.dotmind.classifyTool
import io.github.farhad1618.dotmind.compose.DotMind
import io.github.farhad1618.dotmind.compose.rememberActivityTracker
import io.github.farhad1618.dotmind.labelFor
import kotlinx.coroutines.delay

private data class Sample(val phase: Phase, val tool: String? = null) {
    val activity: Activity = Activity(phase, tool = tool, kind = tool?.let { classifyTool(it) })
    val caption: String = tool ?: phase.id
}

private val States = listOf(
    Sample(Phase.THINKING),
    Sample(Phase.TOOL, "web_search"),
    Sample(Phase.TOOL, "web_fetch"),
    Sample(Phase.TOOL, "bash"),
    Sample(Phase.TOOL, "read_file"),
    Sample(Phase.TOOL, "run_sql"),
    Sample(Phase.TOOL, "calculate_margin"),
    Sample(Phase.TOOL, "get_weather"),
    Sample(Phase.WRITING),
    Sample(Phase.WAITING, "deploy_config"),
    Sample(Phase.ERROR),
    Sample(Phase.DONE),
)

private val OriginalEight = listOf(
    Scene.EMBER, Scene.ORBIT, Scene.PRISM, Scene.SERPENT,
    Scene.CIRCUIT, Scene.PULSE, Scene.COMET, Scene.HALO,
)

private const val LOG_LINES = 6
private val PanelShape = RoundedCornerShape(20.dp)
private val WellShape = RoundedCornerShape(12.dp)
private val ChipShape = RoundedCornerShape(50)

@Composable
fun Showcase() {
    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(Tokens.Stage)
            .windowInsetsPadding(WindowInsets.safeDrawing.only(WindowInsetsSides.Top + WindowInsetsSides.Horizontal))
            .verticalScroll(rememberScrollState())
            .windowInsetsPadding(WindowInsets.safeDrawing.only(WindowInsetsSides.Bottom)),
        contentAlignment = Alignment.TopCenter,
    ) {
        Column(
            modifier = Modifier
                .widthIn(max = 640.dp)
                .fillMaxWidth()
                .padding(horizontal = 20.dp, vertical = 28.dp),
            verticalArrangement = Arrangement.spacedBy(36.dp),
        ) {
            Header()
            LiveStage()
            Section("Every state", "The tool's name decides the picture: web_search sweeps, run_sql lights disks, bash types between brackets.") {
                StateList()
            }
            Section("The original eight", "Fixed scenes for when you only need a loader. Pass scene to pick one.") {
                SceneGrid()
            }
        }
    }
}

@Composable
private fun Header() {
    Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
        BasicText("DOTMIND · COMPOSE", style = Tokens.Eyebrow)
        BasicText("The dots know what the model is doing", style = Tokens.Title)
        BasicText(
            "An 8 × 8 dot matrix follows the model's stream: a drift while it reasons, a sweep while it searches, a filling page while it writes.",
            style = Tokens.Body,
        )
    }
}

@Composable
private fun LiveStage() {
    val tracker = rememberActivityTracker()
    val log = remember { mutableStateListOf<String>() }
    LaunchedEffect(tracker) {
        while (true) {
            tracker.reset()
            log.clear()
            delay(700)
            playTurn(tracker) { line ->
                log.add(0, line)
                if (log.size > LOG_LINES) log.removeAt(log.lastIndex)
            }
        }
    }
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .background(Tokens.Panel, PanelShape)
            .border(1.dp, Tokens.Rule, PanelShape)
            .padding(20.dp),
        verticalArrangement = Arrangement.spacedBy(20.dp),
    ) {
        BasicText("LIVE AGENT TURN", style = Tokens.Eyebrow)
        DotMind(tracker, size = 56.dp, textStyle = Tokens.HeroLabel)
        StepChips(tracker)
        EventLog(log)
    }
}

@OptIn(ExperimentalLayoutApi::class)
@Composable
private fun StepChips(tracker: ActivityTracker) {
    val activity by tracker.activity.collectAsState()
    val current = labelFor(activity)
    FlowRow(
        horizontalArrangement = Arrangement.spacedBy(6.dp),
        verticalArrangement = Arrangement.spacedBy(6.dp),
    ) {
        for (step in TurnSteps) {
            val on = step == current
            BasicText(
                text = step.uppercase(),
                style = Tokens.ChipText.copy(color = if (on) Tokens.Ink else Tokens.InkDim),
                modifier = Modifier
                    .background(if (on) Tokens.ChipOn else Tokens.Chip, ChipShape)
                    .then(if (on) Modifier.border(1.dp, Tokens.Accent, ChipShape) else Modifier)
                    .padding(horizontal = 10.dp, vertical = 7.dp),
            )
        }
    }
}

@Composable
private fun EventLog(lines: List<String>) {
    val text = buildAnnotatedString {
        lines.forEachIndexed { index, line ->
            if (index > 0) append('\n')
            withStyle(SpanStyle(color = if (index == 0) Tokens.Ink else Tokens.InkDim)) { append(line) }
        }
    }
    BasicText(
        text = text,
        style = Tokens.Code,
        minLines = LOG_LINES,
        maxLines = LOG_LINES,
        overflow = TextOverflow.Ellipsis,
        modifier = Modifier
            .fillMaxWidth()
            .background(Tokens.Well, WellShape)
            .padding(horizontal = 14.dp, vertical = 12.dp),
    )
}

@Composable
private fun Section(title: String, body: String, content: @Composable () -> Unit) {
    Column(verticalArrangement = Arrangement.spacedBy(18.dp)) {
        Column(verticalArrangement = Arrangement.spacedBy(6.dp)) {
            BasicText(title, style = Tokens.Heading)
            BasicText(body, style = Tokens.Body)
        }
        content()
    }
}

@Composable
private fun StateList() {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .background(Tokens.Panel, PanelShape)
            .border(1.dp, Tokens.Rule, PanelShape)
            .padding(vertical = 6.dp),
    ) {
        States.forEachIndexed { index, sample ->
            if (index > 0) {
                Spacer(
                    Modifier
                        .padding(horizontal = 16.dp)
                        .fillMaxWidth()
                        .height(1.dp)
                        .background(Tokens.Rule),
                )
            }
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 12.dp, vertical = 10.dp),
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(12.dp),
            ) {
                DotMind(sample.activity, size = 30.dp, textStyle = Tokens.RowLabel)
                BasicText(
                    text = sample.caption,
                    style = Tokens.Caption.copy(textAlign = TextAlign.End),
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis,
                    modifier = Modifier.weight(1f),
                )
            }
        }
    }
}

@Composable
private fun SceneGrid() {
    Column(verticalArrangement = Arrangement.spacedBy(16.dp)) {
        for (row in OriginalEight.chunked(4)) {
            Row(modifier = Modifier.fillMaxWidth()) {
                for (scene in row) {
                    Column(
                        modifier = Modifier.weight(1f),
                        horizontalAlignment = Alignment.CenterHorizontally,
                        verticalArrangement = Arrangement.spacedBy(8.dp),
                    ) {
                        DotMind(Phase.THINKING, size = 40.dp, scene = scene, showLabel = false)
                        BasicText(scene.id, style = Tokens.Caption)
                    }
                }
            }
        }
    }
}
