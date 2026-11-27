import { ActivityTracker } from "../tracker.ts";
import type { AgentEvent } from "../types.ts";

export interface OpenAIResponseItem {
  type: string;
  name?: string;
  id?: string;
  call_id?: string;
  server_label?: string;
}

export interface OpenAIResponsesEvent {
  type: string;
  delta?: string;
  item?: OpenAIResponseItem;
  response?: { output?: OpenAIResponseItem[] };
  message?: string;
}

const SERVER_TOOLS: Record<string, string> = {
  web_search_call: "web_search",
  file_search_call: "file_search",
  code_interpreter_call: "code_interpreter",
  computer_call: "computer",
  image_generation_call: "image_generation",
  local_shell_call: "shell",
  shell_call: "shell",
};
const CLIENT_CALLS = new Set(["function_call", "custom_tool_call", "local_shell_call", "shell_call", "computer_call"]);

function toolName(item: OpenAIResponseItem): string | undefined {
  if (item.type === "function_call" || item.type === "custom_tool_call" || item.type === "mcp_call") return item.name;
  return SERVER_TOOLS[item.type];
}

export function createOpenAIResponsesTranslator(): (event: OpenAIResponsesEvent) => AgentEvent[] {
  return (event) => {
    const item = event.item;
    switch (event.type) {
      case "response.created":
        return [{ type: "start" }];
      case "response.output_item.added": {
        if (!item) return [];
        if (item.type === "reasoning") return [{ type: "thinking" }];
        if (item.type === "message") return [{ type: "text", chars: 0 }];
        if (item.type === "mcp_approval_request") return [{ type: "approval", name: item.name, id: item.id }];
        const name = toolName(item);
        return name ? [{ type: "tool", name, id: item.call_id ?? item.id }] : [];
      }
      case "response.output_item.done":
        if (item && item.type in SERVER_TOOLS && !CLIENT_CALLS.has(item.type)) return [{ type: "tool-result", id: item.id }];
        if (item?.type === "mcp_call") return [{ type: "tool-result", id: item.call_id ?? item.id }];
        return [];
      case "response.reasoning_summary_text.delta":
      case "response.reasoning_text.delta":
        return [{ type: "thinking", chars: event.delta?.length ?? 0 }];
      case "response.output_text.delta":
      case "response.refusal.delta":
        return [{ type: "text", chars: event.delta?.length ?? 0 }];
      case "response.function_call_arguments.delta":
      case "response.custom_tool_call_input.delta":
      case "response.mcp_call_arguments.delta":
        return [{ type: "tool-input", chars: event.delta?.length ?? 0 }];
      case "response.completed":
      case "response.incomplete":
        return [{ type: "finish", pendingTools: !!event.response?.output?.some((o) => CLIENT_CALLS.has(o.type)) }];
      case "response.failed":
      case "error":
        return [{ type: "error", message: event.message }];
      default:
        return [];
    }
  };
}

export interface ChatCompletionChunk {
  choices?: Array<{
    delta?: {
      content?: string | null;
      reasoning?: string | null;
      reasoning_content?: string | null;
      tool_calls?: Array<{ index?: number; id?: string; function?: { name?: string; arguments?: string } }>;
    };
    finish_reason?: string | null;
  }>;
}

export function createChatCompletionsTranslator(): (chunk: ChatCompletionChunk) => AgentEvent[] {
  let started = false;
  return (chunk) => {
    const out: AgentEvent[] = [];
    if (!started) {
      started = true;
      out.push({ type: "start" });
    }
    const choice = chunk.choices?.[0];
    const d = choice?.delta;
    const reasoning = d?.reasoning ?? d?.reasoning_content;
    if (reasoning) out.push({ type: "thinking", chars: reasoning.length });
    for (const call of d?.tool_calls ?? []) {
      if (call.function?.name) out.push({ type: "tool", name: call.function.name, id: call.id });
      if (call.function?.arguments) out.push({ type: "tool-input", chars: call.function.arguments.length });
    }
    if (d?.content) out.push({ type: "text", chars: d.content.length });
    if (choice?.finish_reason) out.push({ type: "finish", pendingTools: choice.finish_reason === "tool_calls" });
    return out;
  };
}

async function follow<E>(
  stream: AsyncIterable<E>,
  translate: (e: E) => AgentEvent[],
  tracker: ActivityTracker,
): Promise<ActivityTracker> {
  try {
    for await (const event of stream) tracker.pushAll(translate(event));
  } catch (err) {
    tracker.push({ type: "error", message: err instanceof Error ? err.message : String(err) });
    throw err;
  }
  return tracker;
}

export function followOpenAIResponses(
  stream: AsyncIterable<OpenAIResponsesEvent>,
  tracker: ActivityTracker = new ActivityTracker(),
): Promise<ActivityTracker> {
  return follow(stream, createOpenAIResponsesTranslator(), tracker);
}

export function followChatCompletions(
  stream: AsyncIterable<ChatCompletionChunk>,
  tracker: ActivityTracker = new ActivityTracker(),
): Promise<ActivityTracker> {
  return follow(stream, createChatCompletionsTranslator(), tracker);
}
