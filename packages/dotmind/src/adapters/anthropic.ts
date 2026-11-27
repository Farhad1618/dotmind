import { ActivityTracker } from "../tracker.ts";
import type { AgentEvent } from "../types.ts";

export interface AnthropicStreamEvent {
  type: string;
  index?: number;
  content_block?: { type: string; name?: string; id?: string; tool_use_id?: string; is_error?: boolean; content?: unknown };
  delta?: { type?: string; text?: string; thinking?: string; partial_json?: string; stop_reason?: string | null };
  error?: { message?: string };
}

const TOOL_CALL_BLOCKS = new Set(["tool_use", "server_tool_use", "mcp_tool_use"]);
const PENDING_STOPS = new Set(["tool_use", "pause_turn"]);

function resultFailed(block: NonNullable<AnthropicStreamEvent["content_block"]>): boolean {
  if (block.is_error) return true;
  const content = block.content as { type?: string } | undefined;
  return typeof content?.type === "string" && content.type.endsWith("error");
}

export function createAnthropicTranslator(): (event: AnthropicStreamEvent) => AgentEvent[] {
  let stopReason: string | null | undefined = null;
  return (event) => {
    switch (event.type) {
      case "message_start":
        stopReason = null;
        return [{ type: "start" }];
      case "content_block_start": {
        const block = event.content_block;
        if (!block) return [];
        if (block.type === "thinking" || block.type === "redacted_thinking") return [{ type: "thinking" }];
        if (block.type === "text") return [{ type: "text", chars: 0 }];
        if (TOOL_CALL_BLOCKS.has(block.type) && block.name) return [{ type: "tool", name: block.name, id: block.id }];
        if (block.type.endsWith("_tool_result")) return [{ type: "tool-result", id: block.tool_use_id, error: resultFailed(block) }];
        return [];
      }
      case "content_block_delta": {
        const d = event.delta;
        if (d?.type === "thinking_delta") return [{ type: "thinking", chars: d.thinking?.length ?? 0 }];
        if (d?.type === "text_delta") return [{ type: "text", chars: d.text?.length ?? 0 }];
        if (d?.type === "input_json_delta") return [{ type: "tool-input", chars: d.partial_json?.length ?? 0 }];
        return [];
      }
      case "message_delta":
        stopReason = event.delta?.stop_reason ?? stopReason;
        return [];
      case "message_stop":
        return [{ type: "finish", pendingTools: stopReason ? PENDING_STOPS.has(stopReason) : false }];
      case "error":
        return [{ type: "error", message: event.error?.message }];
      default:
        return [];
    }
  };
}

export async function followAnthropicStream(
  stream: AsyncIterable<AnthropicStreamEvent>,
  tracker: ActivityTracker = new ActivityTracker(),
): Promise<ActivityTracker> {
  const translate = createAnthropicTranslator();
  try {
    for await (const event of stream) tracker.pushAll(translate(event));
  } catch (err) {
    tracker.push({ type: "error", message: err instanceof Error ? err.message : String(err) });
    throw err;
  }
  return tracker;
}
