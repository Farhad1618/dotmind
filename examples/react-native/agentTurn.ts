import type { ActivityTracker, AgentEvent } from "dotmind-native";

type Step = readonly [AgentEvent, number];

function repeat(event: AgentEvent, times: number, every: number): Step[] {
  return Array.from({ length: times }, () => [event, every] as const);
}

const TURN: readonly Step[] = [
  [{ type: "start" }, 400],
  ...repeat({ type: "thinking", chars: 36 }, 14, 140),
  [{ type: "tool", name: "web_search", id: "search" }, 1600],
  ...repeat({ type: "tool-input", chars: 12 }, 6, 120),
  [{ type: "tool-result", id: "search" }, 140],
  ...repeat({ type: "thinking", chars: 48 }, 8, 140),
  [{ type: "tool", name: "bash", id: "code" }, 1800],
  ...repeat({ type: "tool-input", chars: 24 }, 6, 120),
  [{ type: "tool-result", id: "code" }, 140],
  ...repeat({ type: "text", chars: 14 }, 40, 70),
  [{ type: "finish" }, 2600],
];

export function playAgentTurn(tracker: ActivityTracker): () => void {
  let index = 0;
  let timer: ReturnType<typeof setTimeout> | undefined;

  const step = () => {
    if (index === TURN.length) {
      tracker.reset();
      index = 0;
      timer = setTimeout(step, 700);
      return;
    }
    const [event, wait] = TURN[index++];
    tracker.push(event);
    timer = setTimeout(step, wait);
  };

  timer = setTimeout(step, 500);
  return () => clearTimeout(timer);
}
