import { test } from "node:test";
import assert from "node:assert/strict";
import { ActivityTracker } from "../src/tracker.ts";
import { followAnthropicStream, type AnthropicStreamEvent } from "../src/adapters/anthropic.ts";
import {
  followChatCompletions,
  followOpenAIResponses,
  type ChatCompletionChunk,
  type OpenAIResponsesEvent,
} from "../src/adapters/openai.ts";
import { aiSdkActivity } from "../src/adapters/ai-sdk.ts";
import { ANTHROPIC_TURN } from "../../../demo/fixtures.js";

async function* from<T>(items: T[]) {
  for (const i of items) yield i;
}

function record(tracker: ActivityTracker): string[] {
  const seen: string[] = [];
  tracker.subscribe((a) => {
    const key = a.phase === "tool" || a.phase === "waiting" ? `${a.phase}:${a.tool}` : a.phase;
    if (seen[seen.length - 1] !== key) seen.push(key);
  });
  return seen;
}

test("anthropic: thinking, server search, text, done", async () => {
  const tracker = new ActivityTracker();
  const seen = record(tracker);
  await followAnthropicStream(from(ANTHROPIC_TURN.map(([, e]) => e as AnthropicStreamEvent)), tracker);
  assert.deepEqual(seen, ["idle", "thinking", "tool:web_search", "thinking", "tool:run_sql", "thinking", "writing", "done"]);
});

test("anthropic: a client tool call leaves the tool showing", async () => {
  const tracker = new ActivityTracker();
  await followAnthropicStream(
    from<AnthropicStreamEvent>([
      { type: "message_start" },
      { type: "content_block_start", content_block: { type: "tool_use", name: "bash", id: "t1" } },
      { type: "content_block_delta", delta: { type: "input_json_delta", partial_json: '{"cmd":"ls"}' } },
      { type: "message_delta", delta: { stop_reason: "tool_use" } },
      { type: "message_stop" },
    ]),
    tracker,
  );
  assert.equal(tracker.activity.phase, "tool");
  assert.equal(tracker.activity.kind, "code");
});

test("anthropic: a stream that throws shows the error", async () => {
  const tracker = new ActivityTracker();
  async function* broken() {
    yield { type: "message_start" } as AnthropicStreamEvent;
    throw new Error("overloaded");
  }
  await assert.rejects(followAnthropicStream(broken(), tracker));
  assert.equal(tracker.activity.phase, "error");
});

test("openai responses: reasoning, web search, function call pending", async () => {
  const tracker = new ActivityTracker();
  const seen = record(tracker);
  await followOpenAIResponses(
    from<OpenAIResponsesEvent>([
      { type: "response.created" },
      { type: "response.output_item.added", item: { type: "reasoning" } },
      { type: "response.reasoning_summary_text.delta", delta: "Looking up" },
      { type: "response.output_item.added", item: { type: "web_search_call", id: "ws" } },
      { type: "response.output_item.done", item: { type: "web_search_call", id: "ws" } },
      { type: "response.output_item.added", item: { type: "message" } },
      { type: "response.output_text.delta", delta: "Here is" },
      { type: "response.output_item.added", item: { type: "function_call", name: "read_file", call_id: "c1" } },
      { type: "response.function_call_arguments.delta", delta: '{"path"' },
      { type: "response.completed", response: { output: [{ type: "message" }, { type: "function_call", name: "read_file" }] } },
    ]),
    tracker,
  );
  assert.deepEqual(seen, ["idle", "thinking", "tool:web_search", "thinking", "writing", "tool:read_file"]);
  assert.equal(tracker.activity.kind, "file");
});

test("openai chat completions: reasoning then tool calls", async () => {
  const tracker = new ActivityTracker();
  const seen = record(tracker);
  await followChatCompletions(
    from<ChatCompletionChunk>([
      { choices: [{ delta: { reasoning_content: "hmm" } }] },
      { choices: [{ delta: { content: "Let me check." } }] },
      { choices: [{ delta: { tool_calls: [{ id: "1", function: { name: "search_docs", arguments: "" } }] } }] },
      { choices: [{ delta: { tool_calls: [{ function: { arguments: '{"q":"x"}' } }] } }] },
      { choices: [{ delta: {}, finish_reason: "tool_calls" }] },
    ]),
    tracker,
  );
  assert.deepEqual(seen, ["idle", "thinking", "writing", "tool:search_docs"]);
});

test("ai sdk: derives activity from messages and status", () => {
  const user = { role: "user", parts: [{ type: "text", text: "hi" }] };
  assert.equal(aiSdkActivity([user], "submitted").phase, "thinking");
  const reasoning = { role: "assistant", parts: [{ type: "step-start" }, { type: "reasoning", text: "x", state: "streaming" }] };
  assert.equal(aiSdkActivity([user, reasoning], "streaming").phase, "thinking");
  const toolCall = {
    role: "assistant",
    parts: [{ type: "reasoning", text: "x" }, { type: "tool-searchDocs", state: "input-streaming", input: { q: "a" } }],
  };
  const a = aiSdkActivity([user, toolCall], "streaming");
  assert.deepEqual([a.phase, a.tool, a.kind], ["tool", "searchDocs", "search"]);
  const approval = { role: "assistant", parts: [{ type: "dynamic-tool", toolName: "delete_rows", state: "approval-requested" }] };
  assert.equal(aiSdkActivity([user, approval], "ready").phase, "waiting");
  const writing = {
    role: "assistant",
    parts: [{ type: "tool-searchDocs", state: "output-available" }, { type: "step-start" }, { type: "text", text: "Found it" }],
  };
  assert.equal(aiSdkActivity([user, writing], "streaming").phase, "writing");
  assert.equal(aiSdkActivity([user, writing], "ready").phase, "done");
  assert.equal(aiSdkActivity([user, writing], "error").phase, "error");
  assert.equal(aiSdkActivity([], "ready").phase, "idle");
});
