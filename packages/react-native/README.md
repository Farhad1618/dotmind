# dotmind-native

Dot-matrix status indicators for React Native AI interfaces. The indicator reads the model's stream and shows what the model is doing right now: reasoning, searching, running code, writing. It is the React Native port of [`dotmind`](../dotmind). It uses the same core, so scenes, labels and tool classification match the web package frame for frame.

The 8×8 matrix is drawn with Skia. A frame loop on the JS thread steps the shared `dotmind` renderer, records one Skia picture into reused buffers and paints, and hands it to the canvas through a Reanimated shared value. Frames never re-render React. React renders only when the visible label or scene changes, not on every token. The label shimmer is a Skia gradient driven by Reanimated, so it runs entirely on the UI thread.

## Install

```bash
npm install dotmind-native @shopify/react-native-skia react-native-reanimated react-native-worklets
```

| Peer | Version |
|---|---|
| `react` | 19 or later |
| `react-native` | 0.79 or later, New Architecture (Metro resolves the `dotmind-native/anthropic`, `/openai` and `/ai-sdk` subpaths through package exports, on by default from 0.79) |
| `@shopify/react-native-skia` | 2 or later |
| `react-native-reanimated` | 4 or later (with `react-native-worklets`) |

Bare React Native: add the worklets Babel plugin last in `babel.config.js`, then rebuild the native app (`cd ios && pod install`).

```js
module.exports = {
  presets: ["module:@react-native/babel-preset"],
  plugins: ["react-native-worklets/plugin"],
};
```

Expo: install the peers with `npx expo install @shopify/react-native-skia react-native-reanimated react-native-worklets`. `babel-preset-expo` already includes the worklets plugin. Skia and Reanimated both ship in Expo Go and in development builds.

## Usage

```tsx
import { DotMind } from "dotmind-native";

function Examples() {
  return (
    <>
      <DotMind activity="thinking" />
      <DotMind activity={{ phase: "tool", tool: "web_search" }} />
      <DotMind activity="writing" variant="bare" size={18} />
      <DotMind scene="ember" label="Thinking" />
    </>
  );
}
```

### Anthropic SDK stream

```tsx
import Anthropic from "@anthropic-ai/sdk";
import { fetch as expoFetch } from "expo/fetch";
import { DotMind, useActivityTracker } from "dotmind-native";
import { followAnthropicStream } from "dotmind-native/anthropic";

const client = new Anthropic({
  baseURL: "https://your-backend.example.com/anthropic",
  apiKey: "unused",
  fetch: expoFetch as unknown as typeof fetch,
});
const model = "claude-sonnet-4-5";
const tools: Anthropic.Messages.Tool[] = [
  { name: "web_search", description: "Search the web", input_schema: { type: "object", properties: { query: { type: "string" } }, required: ["query"] } },
];

function Reply() {
  const tracker = useActivityTracker();

  async function ask(question: string) {
    tracker.reset();
    const stream = client.messages.stream({ model, max_tokens: 1024, messages: [{ role: "user", content: question }], tools });
    await followAnthropicStream(stream, tracker);
  }

  return <DotMind tracker={tracker} />;
}
```

A tracker drives the matrix directly. Streamed deltas change the energy and the writing scene without re-rendering your component. The base React Native `fetch` cannot stream response bodies. Use `expo/fetch` (Expo SDK 52 and later) or another streaming fetch. Keep API keys on your server and point the SDK at a relay, as shown above.

### Vercel AI SDK `useChat`

```tsx
import { useChat } from "@ai-sdk/react";
import { DefaultChatTransport } from "ai";
import { fetch as expoFetch } from "expo/fetch";
import { DotMind } from "dotmind-native";
import { aiSdkActivity } from "dotmind-native/ai-sdk";

function Chat() {
  const { messages, status } = useChat({
    transport: new DefaultChatTransport({ api: "https://your-backend.example.com/api/chat", fetch: expoFetch as unknown as typeof fetch }),
  });
  return <DotMind activity={aiSdkActivity(messages, status)} />;
}
```

### Anything else

```ts
import { ActivityTracker } from "dotmind-native";

const tracker = new ActivityTracker({ tools: { lookup_customer: "database" } });
tracker.push({ type: "start" });
tracker.push({ type: "tool", name: "lookup_customer", id: "1" });
tracker.push({ type: "tool-result", id: "1" });
tracker.push({ type: "text", chars: 42 });
tracker.push({ type: "finish" });
```

`dotmind-native/openai` re-exports the OpenAI Responses and Chat Completions adapters (`followOpenAIResponses`, `followChatCompletions`).

## Props

| Prop | Default | |
|---|---|---|
| `activity` | `idle` | What to show. A string is shorthand for `{ phase }`. |
| `tracker` | | Follow an `ActivityTracker`. Updates skip React renders. |
| `variant` | `pill` | `pill` or `bare` (no background, for inline use). |
| `size` | `28` | Matrix size in points. |
| `label` | from state | Fixed text, or `false` to hide it. The accessibility label stays. |
| `labels` | English | Override any label, e.g. `{ "tool:search": "Buscando" }`. |
| `palette` | | Recolour any scene: `{ radar: [0, 200, 120] }`. |
| `scene` | from state | Force one scene, ignoring the state. |
| `reducedMotion` | system setting | Show a still frame per state. |
| `paused` | `false` | Stop the matrix and the shimmer while the indicator is off screen. |
| `theme` | web defaults | `background`, `edge`, `well`, `ink`, `peak`, `fontFamily`, `fontSize`, `shimmerSeconds`. These match the web package's CSS custom properties. |
| `style`, other `View` props | | Passed to the outer view. |

## Behaviour

- One frame loop drives every mounted indicator. It sleeps when nothing animates and pauses while the app is in the background or inactive (`AppState`).
- React Native has no viewport observer, so set `paused` when an indicator is mounted but hidden, for example from navigation focus (`useIsFocused`) or a list's `onViewableItemsChanged`. A paused or backgrounded indicator stops drawing; a state change while it is hidden switches the matrix instantly and paints that one frame, with no crossfade on return.
- A label wider than the space available ends in an ellipsis. The accessibility label keeps the full text.
- When the system's Reduce Motion setting is on (`AccessibilityInfo.isReduceMotionEnabled`) or `reducedMotion` is set, each state is painted once as a settled still frame, and the shimmer stops at its midpoint.
- The indicator is one accessible element. It has `accessibilityRole="progressbar"` while the model is working and `"text"` when idle, done or failed, and it carries the label with `accessibilityLiveRegion="polite"`. On iOS, label changes are queued with `announceForAccessibilityWithOptions`, so VoiceOver hears "Searching", not every frame.
- Label text follows the system font scale.

## Developing in this repo

`dotmind` is a regular dependency (`^0.1.0`). Locally, `package-lock.json` resolves it as a link to `../dotmind`, so build the core first:

```bash
npm install --prefix ../dotmind && npm run build --prefix ../dotmind
npm install
npm run typecheck
npm test
```

If the link is ever lost, `npm run link:core` restores it without changing `package.json`.

## License

MIT
