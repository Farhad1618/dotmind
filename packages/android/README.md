# dotmind for Android

Jetpack Compose port of dotmind. It shows a dot-matrix status indicator that follows an AI model's stream. It renders the same 64 values per frame as the TypeScript reference, and the tests check this against `spec/golden.json`.

| Module | Artifact | What it holds |
|---|---|---|
| `core` | `io.github.farhad1618:dotmind-core:0.2.0` | Pure Kotlin/JVM. `Phase`, `ToolKind`, `Activity`, `AgentEvent`, `classifyTool`, labels, `sceneFor`, looks (`Look`, `LOOKS`, `CLASSIC_SCENES`), cell shapes (`DotShape`), the 26 patterns, `DotRenderer` (clock, energy, per-scene progress origin, smoothstep cross-fade), `ActivityTracker` with a `StateFlow` |
| `adapters` | `io.github.farhad1618:dotmind-adapters:0.2.0` | Pure Kotlin. Anthropic Messages streaming events, OpenAI Responses events and Chat Completions chunks, as kotlinx.serialization models or `JsonObject` input, plus `Flow` followers |
| `compose` | `io.github.farhad1618:dotmind-compose:0.2.0` | Android library. The `@Composable DotMind` |

`core` and `adapters` have no Android or UI imports, so they work on a server or in a plain JVM test as well.

## Install

### From Maven Local

```bash
cd packages/android
./gradlew publishToMavenLocal
```

```kotlin
repositories {
    mavenLocal()
    google()
    mavenCentral()
}

dependencies {
    implementation("io.github.farhad1618:dotmind-compose:0.2.0")
    implementation("io.github.farhad1618:dotmind-adapters:0.2.0")
}
```

`dotmind-compose` brings `dotmind-core` with it. For a backend or a non-Compose UI, depend on `dotmind-core` (plus `dotmind-adapters` if you need it) on its own.

### JitPack

This package has no `jitpack.yml`. JitPack only reads `jitpack.yml` from the root of the repository and runs the build there, so a file in `packages/android` would be ignored. To build with JitPack, add this file at the repository root:

```yaml
jdk:
  - openjdk17
install:
  - cd packages/android && ./gradlew publishToMavenLocal
```

That file sits outside this package, so it is not included here. JitPack serves builds under its own `com.github.<user>` coordinates; the `io.github.farhad1618` coordinates are for Maven Central or Maven Local.

## Usage

### Follow a tracker

The followers take a `Flow` of decoded events. Most HTTP clients hand you a server-sent event stream as one `data:` payload per event, so decode each payload with `AnthropicStreamEvent.decode(String)`. `sseData` below stands for your own source of those payloads, for example an OkHttp `EventSource` wrapped in `callbackFlow`, or a Ktor `sse` session.

```kotlin
import io.github.farhad1618.dotmind.adapters.anthropic.AnthropicStreamEvent
import io.github.farhad1618.dotmind.adapters.anthropic.followAnthropicStream
import io.github.farhad1618.dotmind.compose.DotMind
import io.github.farhad1618.dotmind.compose.rememberActivityTracker
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.filter
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.launch

@Composable
fun Reply(sseData: () -> Flow<String>) {
    val tracker = rememberActivityTracker()
    val scope = rememberCoroutineScope()

    Button(onClick = {
        scope.launch {
            val events = sseData()
                .filter { it.isNotBlank() && it != "[DONE]" }
                .map { AnthropicStreamEvent.decode(it) }
            followAnthropicStream(events, tracker)
        }
    }) { Text("Ask") }

    DotMind(tracker)
}
```

If your client already parses each event into a `JsonObject`, pass `jsonEvents.asAnthropicEvents()` instead.

When the tracker is followed, progress ticks update the drawing without recomposing. Recomposition happens only when the label or the phase changes.

### Drive it yourself

```kotlin
DotMind(Phase.THINKING)
DotMind(Activity(Phase.TOOL, tool = "web_search", kind = ToolKind.SEARCH))
DotMind(Phase.IDLE, scene = Scene.EMBER, label = "Thinking")
```

### Looks

A look swaps the pictures for some states, the cell shape and whether the pill glows. The same tracker and labels drive every look.

```kotlin
DotMind(tracker, look = Look.ICONS)
DotMind(tracker, look = Look.PIXEL)
DotMind(tracker, look = Look.PIXEL, shape = DotShape.DOT, aura = true)
DotMind(tracker, look = Look.ICONS, scenes = mapOf(SceneKey.THINKING to Scene.ORBIT))
```

| Look | Scenes that change | Shape | Aura |
|---|---|---|---|
| `Look.CLASSIC` | none | `DotShape.DOT` | off |
| `Look.ICONS` | thinking: neural, done: verified, search: magnifier, translate: glyph, compute: sort, deploy: rocket | `DotShape.DOT` | on |
| `Look.PIXEL` | debug: bug, code: blocks, search: scan | `DotShape.SQUARE` | off |

The scene for a state is picked in this order: the `scene` parameter, then the `scenes` map (keyed by `SceneKey`, for example `SceneKey.TOOL_DEBUG`), then the look, then the classic table. `Look.fromId` returns `Look.CLASSIC` for a name it does not know. `sceneFor(activity, look, overrides)` and `sceneKey(activity)` in `core` do the same outside Compose.

The aura is a soft glow in the current scene colour around the pill, or around the matrix well for `DotMindVariant.Bare`. It follows the scene colour through the same 0.35 s cross-fade as the dots, and fades in or out over 0.35 s when it is switched.

### Push events

```kotlin
val tracker = ActivityTracker(tools = mapOf("lookup_customer" to ToolKind.DATABASE))
tracker.push(AgentEvent.Start)
tracker.push(AgentEvent.Tool("lookup_customer", id = "1"))
tracker.push(AgentEvent.ToolResult(id = "1"))
tracker.push(AgentEvent.Text(chars = 42))
tracker.push(AgentEvent.Finish())

val unsubscribe = tracker.subscribe { activity -> println(activity.phase) }
unsubscribe()
```

`subscribe` calls the listener at once with the current activity and then on every change, in order, from whichever thread pushes. To observe from a coroutine, collect `tracker.activity` inside `scope.launch { }` or a `LaunchedEffect`.

If a turn ends because the model wants your code to run a tool (`stop_reason: "tool_use"`, `finish_reason: "tool_calls"`, or a client call in a Responses output), the indicator stays on that tool until the next turn starts.

### Adapters

| Source | Model | Follower | Translator |
|---|---|---|---|
| Anthropic Messages stream | `AnthropicStreamEvent` | `followAnthropicStream(flow, tracker)` | `AnthropicTranslator` |
| OpenAI Responses | `OpenAIResponsesEvent` | `followOpenAIResponses(flow, tracker)` | `OpenAIResponsesTranslator` |
| Chat Completions (OpenAI, OpenRouter, Ollama, vLLM, DeepSeek `reasoning_content`) | `ChatCompletionChunk` | `followChatCompletions(flow, tracker)` | `ChatCompletionsTranslator` |

Each model has `decode(String)` and `decode(JsonObject)`. A `Flow<JsonObject>` can be turned into a model flow with `asAnthropicEvents()`, `asOpenAIResponsesEvents()` or `asChatCompletionChunks()`. If the flow throws, the follower marks the tracker as `error` and rethrows the exception. Cancellation is passed through without marking an error. Any other source can use `Flow<E>.followWith(translator, tracker)`.

The Vercel AI SDK adapter from the web package is not ported, because `useChat` messages do not exist on Android.

## Options

| Parameter | Default | |
|---|---|---|
| `activity` / `phase` / `tracker` | | What to show |
| `variant` | `DotMindVariant.Pill` | `Pill` or `Bare` (no background, for inline use) |
| `size` | `28.dp` | Matrix side |
| `label` | from state | Fixed text |
| `showLabel` | `true` | `false` hides the text. It is still announced |
| `labels` | English | e.g. `mapOf(LabelKey.TOOL_SEARCH to "Buscando")` |
| `palette` | | e.g. `mapOf(Scene.RADAR to Rgb(0, 200, 120))` |
| `scene` | from state | Force one scene |
| `look` | `Look.CLASSIC` | `CLASSIC`, `ICONS` or `PIXEL` |
| `shape` | from the look | `DotShape.DOT` (round, 14% base alpha) or `DotShape.SQUARE` (rounded squares, 20% base alpha) |
| `scenes` | | Per-state scene overrides, e.g. `mapOf(SceneKey.TOOL_DEBUG to Scene.BUG)` |
| `aura` | from the look | `true` or `false` turns the glow on or off whatever the look says |
| `reducedMotion` | system setting | Shows one still frame per state |
| `colors` | `DotMindDefaults.Colors` | Pill background, edge, well, label ink and shimmer peak |
| `textStyle` | `DotMindDefaults.LabelStyle` | Label font; the pill spacing scales with its size |
| `shimmerDuration` | `DotMindDefaults.ShimmerDuration` (2.4 s) | One sweep of the label shimmer, like `--dm-shimmer` on the web |

## Behaviour

- **Frame loop.** Drawing is driven by `withFrameNanos`. Each step is capped at 50 ms.
- **No per-frame allocation.** The draw path reuses its value and colour buffers. A core test measures allocation over 20,000 frames to check this.
- **Pausing.** The loop stops while the indicator is off screen (empty window bounds) or the lifecycle is below `STARTED`, for example when the app is in the background.
- **Reduced motion.** When the system animator scale is 0, or `reducedMotion = true`, the indicator shows one settled still frame for each state and runs no loop. The label highlight rests in the middle of the text for active states and is plain ink for idle, done and error, as on the web.
- **Accessibility.** The indicator is one node with the label as its content description and a polite live region. TalkBack hears "Searching", not every frame. The canvas and the visible text are cleared from the semantics tree.

## Develop

Requires JDK 17 and an Android SDK with platform 35.

```bash
export JAVA_HOME=/path/to/jdk17
export ANDROID_HOME=$HOME/Library/Android/sdk
./gradlew :core:test :adapters:test :compose:testDebugUnitTest :compose:assembleRelease :example:assembleDebug
```

`core` tests load `../../spec/golden.json` and check every frame, tool kind, scene and label, look, and energy sample against the fixture's tolerance. To match the reference, the port follows the numeric rules in `spec/SPEC.md` section 7: 64-bit maths, `floor(x + 0.5)` rounding, positive modulo, fdlibm `sin` through `StrictMath`, and Float32 output buffers like the reference's `Float32Array`.
