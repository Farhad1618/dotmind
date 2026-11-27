## 0.1.0

- First release of the Flutter port.
- Pure Dart core: `Activity`, `AgentEvent`, `classifyTool` with overrides, labels, `sceneFor`, all 17 patterns, `DotRenderer` with clock, energy, per-scene progress origin and smoothstep cross-fade, and `ActivityTracker` as a `ValueListenable<Activity>`.
- Adapters for Anthropic Messages streaming events, OpenAI Responses events and Chat Completions chunks, plus `followStream`, which marks the tracker as failed when the stream errors.
- `DotMind` widget with pill and bare variants, a shimmer label, a polite live region for screen readers, still frames when animations are disabled, and drawing that pauses when the ticker is muted or the app is in the background.
- Matches the TypeScript reference within the tolerance of `spec/golden.json`.
