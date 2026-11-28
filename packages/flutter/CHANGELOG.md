## 0.2.0

- New tool kinds `translate`, `deploy` and `debug`, labelled Translating, Deploying and Debugging. Their rules run after the existing ones, so every tool name keeps the kind it had.
- Nine new scenes: `neural`, `magnifier`, `glyph`, `sort`, `rocket` and `verified` for the icons look, `bug`, `blocks` and `scan` for the pixel look. The classic look shows `glyph`, `rocket` and `bug` for the new kinds.
- Looks: `Look.classic`, `Look.icons` and `Look.pixel`, each a table of scenes plus a default cell shape and aura. `sceneFor` takes `look` and `overrides`; `SceneKey` names each state; `classicScenes`, `looks` and `lookDefinition` expose the tables.
- `CellShape.dot` and `CellShape.square`. Squares are 0.8 of the step with a 0.22 corner and a 0.20 base alpha, and the well rounds to 14% instead of 24%.
- An aura: a soft glow in the scene colour around the pill, or around the well when bare, that cross-fades over 0.35 s. On by default for the icons look.
- `DotMind` and `DotMind.phase` take `look`, `shape`, `scenes` and `aura`.
- Matches the 208 frames, 33 tools, 17 scenes and the looks section of `spec/golden.json`.

## 0.1.0

- First release of the Flutter port.
- Pure Dart core: `Activity`, `AgentEvent`, `classifyTool` with overrides, labels, `sceneFor`, all 17 patterns, `DotRenderer` with clock, energy, per-scene progress origin and smoothstep cross-fade, and `ActivityTracker` as a `ValueListenable<Activity>`.
- Adapters for Anthropic Messages streaming events, OpenAI Responses events and Chat Completions chunks, plus `followStream`, which marks the tracker as failed when the stream errors.
- `DotMind` widget with pill and bare variants, a shimmer label, a polite live region for screen readers, still frames when animations are disabled, and drawing that pauses when the ticker is muted or the app is in the background.
- Matches the TypeScript reference within the tolerance of `spec/golden.json`.
