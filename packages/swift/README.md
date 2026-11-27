# dotmind for SwiftUI

Dot-matrix status indicators for AI interfaces, ported from the TypeScript reference in `packages/dotmind`. The indicator reads the model's stream and shows what the model is doing right now: thinking, searching, running code, writing, waiting, failed or done.

Every scene produces the same 64 values as the web package for the same inputs. The tests check this against `spec/golden.json`.

## Install

```swift
dependencies: [
    .package(url: "https://github.com/Farhad1618/dotmind", branch: "main"),
],
targets: [
    .target(name: "App", dependencies: [.product(name: "DotMind", package: "dotmind")]),
]
```

There is no release tag yet, so depend on `main` until one is published.

Platforms: iOS 15, macOS 12, tvOS 15, watchOS 10, visionOS 1. No dependencies.

The `DotMind` product is the SwiftUI view and re-exports everything in `DotMindCore`. Depend on `DotMindCore` alone for the tracker, adapters and renderer without SwiftUI.

## SwiftUI

```swift
import DotMind
import SwiftUI

struct ReplyView: View {
    @StateObject private var tracker = ActivityTracker()

    var body: some View {
        DotMindView(tracker: tracker)
            .task { await ask() }
    }
}
```

Or drive it yourself:

```swift
DotMindView(activity: .thinking)
DotMindView(activity: .using("web_search"))
DotMindView(activity: .writing, variant: .bare, size: 18)
DotMindView(activity: .thinking, label: .text("Thinking"), scene: .ember)
```

## Following an Anthropic stream

Each adapter takes `Decodable` event structs decoded from the raw SSE JSON, so it works with `URLSession` or any Swift client. `serverSentEvents(_:)` turns an async sequence of SSE lines into decoded events.

This `ask()` belongs in `ReplyView` above. `apiKey` and `requestBody` (the encoded Messages request with `"stream": true`) are yours to supply.

```swift
func ask() async {
    var request = URLRequest(url: URL(string: "https://api.anthropic.com/v1/messages")!)
    request.httpMethod = "POST"
    request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
    request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
    request.setValue("application/json", forHTTPHeaderField: "content-type")
    request.httpBody = requestBody

    do {
        let (bytes, _) = try await URLSession.shared.bytes(for: request)
        let events = bytes.lines.serverSentEvents(AnthropicStreamEvent.self)
        try await followAnthropicStream(events, tracker: tracker)
    } catch {
    }
}
```

If the sequence throws, the tracker switches to `error` and the error is rethrown.

| Source | Event type | Follow helper | Translator |
|---|---|---|---|
| Anthropic Messages streaming, including server tools and MCP tool blocks | `AnthropicStreamEvent` | `followAnthropicStream` | `AnthropicTranslator` |
| OpenAI Responses API | `OpenAIResponsesEvent` | `followOpenAIResponses` | `OpenAIResponsesTranslator` |
| OpenAI Chat Completions chunks (also OpenRouter, Ollama, vLLM, DeepSeek `reasoning_content`) | `ChatCompletionChunk` | `followChatCompletions` | `ChatCompletionsTranslator` |

When a turn ends because the model asked your code to run a tool (`stop_reason` `tool_use` or `pause_turn`, `finish_reason` `tool_calls`), the indicator stays on that tool until the next turn starts.

Any other source: push events into a tracker yourself.

```swift
let tracker = ActivityTracker(tools: ["lookup_customer": .database])
tracker.push(.start)
tracker.push(.tool(name: "lookup_customer", id: "1"))
tracker.push(.toolResult(id: "1"))
tracker.push(.text(chars: 42))
tracker.push(.finish())
```

`ActivityTracker` is a main-actor `ObservableObject`. Its `activity` property is `@Published`, so you can use it from `@StateObject`, Combine (`tracker.$activity`) or as a property of an `@Observable` model.

## Options

| Parameter | Default | |
|---|---|---|
| `activity` / `tracker` | `.idle` | What to show, or a tracker to follow. |
| `variant` | `.pill` | `.pill` or `.bare` (no background, for inline use). |
| `size` | `28` | Matrix size in points. |
| `label` | `.automatic` | `.text("…")` for fixed text, `.hidden` to hide it. |
| `labels` | English | Override any label, e.g. `[.tool(.search): "Buscando"]`. |
| `palette` | | Recolour any scene: `[.radar: RGB(0, 200, 120)]`. |
| `scene` | from state | Force one scene, ignoring the state. |
| `reducedMotion` | system setting | Show a still frame per state. |

Colours, font and shimmer speed come from `.dotMindTheme(DotMindTheme(...))`.

The matrix is drawn in a `Canvas` inside `TimelineView(.animation)`. The timeline pauses when Reduce Motion is on, when the view is removed from the hierarchy (or not yet loaded in a lazy container) and when the app is in the background. A view in a plain `ScrollView` that is scrolled out of sight stays in the hierarchy and keeps animating. The view is one accessibility element with the label as its accessibility label. When the label changes, VoiceOver hears it as a queued announcement on every platform, watchOS included, so it says "Searching" once instead of reading every frame.

## Core without SwiftUI

`import DotMindCore`. `classifyTool`, `labelFor`, `sceneFor`, `SceneName.render(at:into:context:)` and `DotRenderer` are plain Swift with no UI imports. You can use them to draw the matrix in another renderer.

## Tests

From the repo root:

```bash
swift test
```
