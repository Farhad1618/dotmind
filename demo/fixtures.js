const chunk = (text, size) => {
  const out = [];
  for (let i = 0; i < text.length; i += size) out.push(text.slice(i, i + size));
  return out;
};

const THINK_1 =
  "The user wants last quarter's churn by region and why the Gulf number moved. I should check for any published notes on pricing changes first, then pull the actual numbers from the warehouse rather than guessing.";
const THINK_2 =
  "Search says a price change landed in the Gulf in August. Now I need churned accounts by region for Q3 against Q2 to see if the timing lines up.";
const THINK_3 = "Gulf churn went from 3.1% to 5.4%, the rest stayed flat. That matches the August change.";
const ANSWER =
  "Churn rose in one region only. Gulf churn climbed from 3.1% in Q2 to 5.4% in Q3, while every other region stayed within 0.3 points of the previous quarter. The jump starts in the first week of August, the same week the new Gulf price list took effect, and 71% of the churned Gulf accounts were on the entry plan that saw the largest increase. I would look at a targeted retention offer for entry-plan accounts in the Gulf before changing prices anywhere else.";

const at = (ms, event) => [ms, event];

export const ANTHROPIC_TURN = [
  at(0, { type: "message_start", message: { role: "assistant" } }),
  at(220, { type: "content_block_start", index: 0, content_block: { type: "thinking", thinking: "" } }),
  ...chunk(THINK_1, 14).map((t) => at(70, { type: "content_block_delta", index: 0, delta: { type: "thinking_delta", thinking: t } })),
  at(40, { type: "content_block_stop", index: 0 }),
  at(60, { type: "content_block_start", index: 1, content_block: { type: "server_tool_use", id: "srv_1", name: "web_search", input: {} } }),
  at(120, { type: "content_block_delta", index: 1, delta: { type: "input_json_delta", partial_json: '{"query":"gulf pricing change august"}' } }),
  at(40, { type: "content_block_stop", index: 1 }),
  at(2600, { type: "content_block_start", index: 2, content_block: { type: "web_search_tool_result", tool_use_id: "srv_1", content: [] } }),
  at(40, { type: "content_block_stop", index: 2 }),
  at(80, { type: "content_block_start", index: 3, content_block: { type: "thinking", thinking: "" } }),
  ...chunk(THINK_2, 14).map((t) => at(60, { type: "content_block_delta", index: 3, delta: { type: "thinking_delta", thinking: t } })),
  at(40, { type: "content_block_stop", index: 3 }),
  at(60, { type: "content_block_start", index: 4, content_block: { type: "mcp_tool_use", id: "mcp_1", name: "run_sql", server_name: "warehouse", input: {} } }),
  ...chunk('{"sql":"select region, quarter, churn_rate from churn_by_region where quarter in (\'Q2\',\'Q3\')"}', 12).map((t) =>
    at(45, { type: "content_block_delta", index: 4, delta: { type: "input_json_delta", partial_json: t } }),
  ),
  at(40, { type: "content_block_stop", index: 4 }),
  at(2400, { type: "content_block_start", index: 5, content_block: { type: "mcp_tool_result", tool_use_id: "mcp_1", is_error: false, content: [] } }),
  at(40, { type: "content_block_stop", index: 5 }),
  at(80, { type: "content_block_start", index: 6, content_block: { type: "thinking", thinking: "" } }),
  ...chunk(THINK_3, 12).map((t) => at(80, { type: "content_block_delta", index: 6, delta: { type: "thinking_delta", thinking: t } })),
  at(40, { type: "content_block_stop", index: 6 }),
  at(100, { type: "content_block_start", index: 7, content_block: { type: "text", text: "" } }),
  ...chunk(ANSWER, 6).map((t, i) =>
    at(i > 30 && i < 42 ? 140 : 28, { type: "content_block_delta", index: 7, delta: { type: "text_delta", text: t } }),
  ),
  at(40, { type: "content_block_stop", index: 7 }),
  at(40, { type: "message_delta", delta: { stop_reason: "end_turn" } }),
  at(20, { type: "message_stop" }),
];

export const OPENAI_TURN = [
  at(0, { type: "response.created" }),
  at(200, { type: "response.output_item.added", item: { type: "reasoning" } }),
  ...chunk("Need the config file before changing the retry policy.", 10).map((t) =>
    at(90, { type: "response.reasoning_summary_text.delta", delta: t }),
  ),
  at(80, { type: "response.output_item.added", item: { type: "function_call", name: "read_file", call_id: "c1" } }),
  ...chunk('{"path":"services/billing/retry.yaml"}', 8).map((t) => at(60, { type: "response.function_call_arguments.delta", delta: t })),
  at(2200, { type: "response.output_item.added", item: { type: "code_interpreter_call", id: "ci_1" } }),
  at(2600, { type: "response.output_item.done", item: { type: "code_interpreter_call", id: "ci_1" } }),
  at(80, { type: "response.output_item.added", item: { type: "mcp_approval_request", name: "deploy_config", id: "ap1" } }),
  at(2400, { type: "response.output_item.added", item: { type: "message" } }),
  ...chunk(
    "The retry policy now backs off exponentially from 2 seconds and stops after 6 attempts. I simulated a day of failed charges against it: retries per invoice drop from 14 to 6 and the recovered amount stays the same.",
    5,
  ).map((t) => at(26, { type: "response.output_text.delta", delta: t })),
  at(60, { type: "response.completed", response: { output: [{ type: "message" }] } }),
];
