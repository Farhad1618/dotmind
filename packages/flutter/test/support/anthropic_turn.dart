import 'package:dotmind/adapters.dart';

List<String> _chunk(String text, int size) => [
  for (var i = 0; i < text.length; i += size) text.substring(i, i + size > text.length ? text.length : i + size),
];

const String _think1 =
    "The user wants last quarter's churn by region and why the Gulf number moved. "
    'I should check for any published notes on pricing changes first, then pull the actual numbers '
    'from the warehouse rather than guessing.';
const String _think2 =
    'Search says a price change landed in the Gulf in August. Now I need churned accounts by region '
    'for Q3 against Q2 to see if the timing lines up.';
const String _think3 = 'Gulf churn went from 3.1% to 5.4%, the rest stayed flat. That matches the August change.';
const String _answer =
    'Churn rose in one region only. Gulf churn climbed from 3.1% in Q2 to 5.4% in Q3, while every other '
    'region stayed within 0.3 points of the previous quarter.';

JsonMap _thinkingDelta(int index, String text) => {
  'type': 'content_block_delta',
  'index': index,
  'delta': {'type': 'thinking_delta', 'thinking': text},
};

JsonMap _inputDelta(int index, String json) => {
  'type': 'content_block_delta',
  'index': index,
  'delta': {'type': 'input_json_delta', 'partial_json': json},
};

JsonMap _stop(int index) => {'type': 'content_block_stop', 'index': index};

final List<JsonMap> anthropicTurn = [
  {
    'type': 'message_start',
    'message': {'role': 'assistant'},
  },
  {
    'type': 'content_block_start',
    'index': 0,
    'content_block': {'type': 'thinking', 'thinking': ''},
  },
  for (final t in _chunk(_think1, 14)) _thinkingDelta(0, t),
  _stop(0),
  {
    'type': 'content_block_start',
    'index': 1,
    'content_block': {'type': 'server_tool_use', 'id': 'srv_1', 'name': 'web_search', 'input': <String, Object?>{}},
  },
  _inputDelta(1, '{"query":"gulf pricing change august"}'),
  _stop(1),
  {
    'type': 'content_block_start',
    'index': 2,
    'content_block': {'type': 'web_search_tool_result', 'tool_use_id': 'srv_1', 'content': <Object?>[]},
  },
  _stop(2),
  {
    'type': 'content_block_start',
    'index': 3,
    'content_block': {'type': 'thinking', 'thinking': ''},
  },
  for (final t in _chunk(_think2, 14)) _thinkingDelta(3, t),
  _stop(3),
  {
    'type': 'content_block_start',
    'index': 4,
    'content_block': {
      'type': 'mcp_tool_use',
      'id': 'mcp_1',
      'name': 'run_sql',
      'server_name': 'warehouse',
      'input': <String, Object?>{},
    },
  },
  for (final t in _chunk('{"sql":"select region, quarter, churn_rate from churn_by_region"}', 12)) _inputDelta(4, t),
  _stop(4),
  {
    'type': 'content_block_start',
    'index': 5,
    'content_block': {'type': 'mcp_tool_result', 'tool_use_id': 'mcp_1', 'is_error': false, 'content': <Object?>[]},
  },
  _stop(5),
  {
    'type': 'content_block_start',
    'index': 6,
    'content_block': {'type': 'thinking', 'thinking': ''},
  },
  for (final t in _chunk(_think3, 12)) _thinkingDelta(6, t),
  _stop(6),
  {
    'type': 'content_block_start',
    'index': 7,
    'content_block': {'type': 'text', 'text': ''},
  },
  for (final t in _chunk(_answer, 6))
    {
      'type': 'content_block_delta',
      'index': 7,
      'delta': {'type': 'text_delta', 'text': t},
    },
  _stop(7),
  {
    'type': 'message_delta',
    'delta': {'stop_reason': 'end_turn'},
  },
  {'type': 'message_stop'},
];
