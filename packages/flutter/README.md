# dotmind

Dot-matrix status indicators for AI interfaces in Flutter. Instead of a spinner you switch on and off yourself, dotmind reads the model's stream and shows what the model is doing right now.

This is the Flutter port of [dotmind](https://github.com/Farhad1618/dotmind). It draws the same 64 values as the TypeScript reference for the same inputs, checked against the shared parity fixture.

| The model is… | The dots show | The label says |
|---|---|---|
| reasoning | a comet tracing a figure-eight | Thinking |
| calling a search tool (`web_search`, `search_docs`, `grep`) | a radar sweep with blips | Searching |
| fetching or browsing (`web_fetch`, `navigate`) | a turning globe | Browsing |
| running code (`bash`, `code_interpreter`) | a cursor typing between `< >` | Running code |
| reading or editing files (`read_file`, `text_editor`) | a page being read line by line | Reading files |
| querying data (`run_sql`, `query_clickhouse`) | stacked disks lighting in turn | Querying data |
| calculating (`calculate_margin`, `plot`) | a breathing diamond | Calculating |
| translating (`translate_text`, `i18n_sync`) | one glyph sweeping into another | Translating |
| deploying (`deploy_service`, `kubectl_apply`) | a rocket lifting off | Deploying |
| debugging (`set_breakpoint`, `parse_traceback`) | a bug assembling from noise | Debugging |
| any other tool (`get_weather`) | a trace around the edge | Using get weather |
| writing the answer | lines filling in as text arrives | Writing |
| waiting for approval | a slow spinner | Waiting for you |
| failed | a flashing cross | Something went wrong |
| finished | a check mark drawn in | Done |

The writing scene moves one dot for every four characters received, the matrix speeds up and brightens with the token rate and settles when the stream stalls, and scenes cross-fade into each other.

## Install

```yaml
dependencies:
  dotmind: ^0.2.0
```

## Follow a stream

```dart
import 'package:dotmind/adapters.dart';
import 'package:dotmind/dotmind.dart';
import 'package:flutter/widgets.dart';

class AgentStatus extends StatefulWidget {
  const AgentStatus({super.key, required this.events});

  final Stream<Map<String, Object?>> events;

  @override
  State<AgentStatus> createState() => _AgentStatusState();
}

class _AgentStatusState extends State<AgentStatus> {
  final ActivityTracker _tracker = ActivityTracker();

  @override
  void initState() {
    super.initState();
    followAnthropicStream(widget.events, _tracker).ignore();
  }

  @override
  void dispose() {
    _tracker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => DotMind(tracker: _tracker);
}
```

The adapters take decoded JSON maps, so they work with any HTTP or SSE client.

| Function | Source |
|---|---|
| `followAnthropicStream`, `AnthropicTranslator` | Anthropic Messages streaming events, including server tools and MCP tool blocks |
| `followOpenAIResponses`, `OpenAIResponsesTranslator` | OpenAI Responses API events |
| `followChatCompletions`, `ChatCompletionsTranslator` | Chat Completions chunks, including `reasoning` and `reasoning_content` from OpenRouter, Ollama, vLLM and DeepSeek |
| `followStream` | Any stream plus your own translator |

Every `follow…` function pushes an error into the tracker and rethrows when the stream fails.

When a turn ends because the model asked your code to run a tool (`stop_reason: "tool_use"`, `finish_reason: "tool_calls"`), the indicator stays on that tool until the next turn starts.

## Drive it yourself

```dart
const DotMind(activity: Activity(Phase.thinking));
DotMind(activity: Activity.usingTool('web_search'));
const DotMind(scene: Scene.ember, label: 'Thinking');
```

## Looks

A look re-skins every state at once. It picks the scenes, the cell shape and whether the pill glows.

| Look | Scenes it changes | Shape | Aura |
|---|---|---|---|
| `Look.classic` | none | dots | off |
| `Look.icons` | thinking → `neural`, done → `verified`, search → `magnifier`, translate → `glyph`, compute → `sort`, deploy → `rocket` | dots | on |
| `Look.pixel` | debug → `bug`, code → `blocks`, search → `scan` | squares | off |

```dart
DotMind(tracker: tracker, look: Look.icons);
DotMind(tracker: tracker, look: Look.pixel, aura: true);
DotMind(
  tracker: tracker,
  look: Look.icons,
  shape: CellShape.square,
  scenes: const {SceneKey.thinking: Scene.ember, SceneKey.toolCode: Scene.blocks},
);
```

The scene is chosen in this order: `scene`, then `scenes`, then the look's table, then the classic table. `shape` and `aura` override the look's defaults. The same rules are available without a widget through `sceneFor(activity, look: Look.icons, overrides: {...})`.

Or push events into a tracker:

```dart
final tracker = ActivityTracker(tools: {'lookup_customer': ToolKind.database});
tracker
  ..push(const AgentEvent.start())
  ..push(const AgentEvent.tool('lookup_customer', id: '1'))
  ..push(const AgentEvent.toolResult(id: '1'))
  ..push(const AgentEvent.text(chars: 42))
  ..push(const AgentEvent.finish());
```

`ActivityTracker` is a `ValueListenable<Activity>`, so it also works with `ValueListenableBuilder`. `DotMind` accepts any `ValueListenable<Activity>` as its `tracker`, and progress-only updates do not rebuild the widget.

## Options

| Parameter | Default | |
|---|---|---|
| `activity` | `Activity.idle` | What to show. A tool name without a kind is classified for you. |
| `tracker` | | Follow a tracker or any `ValueListenable<Activity>`. Takes precedence over `activity`. |
| `variant` | `DotMindVariant.pill` | `pill` or `bare` (no background, for inline use). |
| `size` | `28` | Matrix size in logical pixels. |
| `label` | from state | Fixed text. |
| `showLabel` | `true` | Hide the text. Screen readers still hear the state. |
| `labels` | English | Override any label, for example `{toolLabelKey(ToolKind.search): 'Buscando'}` or `{'thinking': 'Pensando'}`. |
| `palette` | | Recolour any scene: `{Scene.radar: Rgb(0, 200, 120)}`. |
| `scene` | from state | Force one scene, ignoring the state. |
| `look` | `Look.classic` | `classic`, `icons` or `pixel`. |
| `shape` | from look | `CellShape.dot` or `CellShape.square`. |
| `scenes` | | Pick the scene per state: `{SceneKey.toolSearch: Scene.magnifier}`. Beats the look, loses to `scene`. |
| `aura` | from look | A glow in the scene colour around the pill, or the well when bare. Cross-fades with the scene. |
| `reducedMotion` | system setting | Show a still frame per state. |
| `style` | dark pill | `DotMindStyle` with background, edge, well, ink, peak, text style and shimmer period. |

## Behaviour

- The label sits in a polite live region, so screen readers hear each state change, and the dot matrix is hidden from accessibility services.
- With `MediaQuery.disableAnimations` (or `reducedMotion: true`) each state is drawn once as a still frame and no ticker runs. The aura then changes colour without fading.
- Drawing stops while the widget's `TickerMode` is disabled, such as an offstage route or tab, and while the app is hidden or paused.
- The paint path reuses its buffers, paints and blur filters, and caches colours per brightness level, so a steady frame allocates nothing.

## Architecture

- `lib/src/core`: pure logic with no widget imports. Types, tool classification, labels, scene keys, looks, cell shapes, scene selection, the 26 patterns, `DotRenderer` and `ActivityTracker`.
- `lib/src/adapters`: stream translators that map provider events to `AgentEvent`s.
- `lib/src/widgets`: `DotMind`, the ticker-driven matrix, its painter, the aura and the shimmer label.

The rendering contract lives in [`spec/SPEC.md`](https://github.com/Farhad1618/dotmind/blob/main/spec/SPEC.md), and the tests in this package assert every frame, tool kind, scene, look, label and energy sample in `spec/golden.json`.

## Example

`example/lib/main.dart` shows a live turn and every state under a Look switch, the icons and pixel scenes, the original ambient scenes and the bare variant.

## License

MIT
