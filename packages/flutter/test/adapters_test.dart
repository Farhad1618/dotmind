import 'package:dotmind/adapters.dart';
import 'package:dotmind/dotmind.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/anthropic_turn.dart';
import 'support/streams.dart';

void main() {
  test('anthropic: thinking, server search, text, done', () async {
    final tracker = ActivityTracker();
    final seen = record(tracker);
    await followAnthropicStream(streamOf(anthropicTurn), tracker);
    expect(seen, ['idle', 'thinking', 'tool:web_search', 'thinking', 'tool:run_sql', 'thinking', 'writing', 'done']);
  });

  test('anthropic: a client tool call leaves the tool showing', () async {
    final tracker = ActivityTracker();
    await followAnthropicStream(
      streamOf<JsonMap>([
        {'type': 'message_start'},
        {
          'type': 'content_block_start',
          'content_block': {'type': 'tool_use', 'name': 'bash', 'id': 't1'},
        },
        {
          'type': 'content_block_delta',
          'delta': {'type': 'input_json_delta', 'partial_json': '{"cmd":"ls"}'},
        },
        {
          'type': 'message_delta',
          'delta': {'stop_reason': 'tool_use'},
        },
        {'type': 'message_stop'},
      ]),
      tracker,
    );
    expect(tracker.activity.phase, Phase.tool);
    expect(tracker.activity.kind, ToolKind.code);
  });

  test('anthropic: a stream that throws shows the error', () async {
    final tracker = ActivityTracker();
    Stream<JsonMap> broken() async* {
      yield {'type': 'message_start'};
      throw StateError('overloaded');
    }

    await expectLater(followAnthropicStream(broken(), tracker), throwsStateError);
    expect(tracker.activity.phase, Phase.error);
  });

  test('anthropic: translator maps failed results and error events', () {
    final translate = AnthropicTranslator();
    expect(
      translate({
        'type': 'content_block_start',
        'content_block': {
          'type': 'web_fetch_tool_result',
          'tool_use_id': 'f1',
          'content': {'type': 'web_fetch_tool_result_error'},
        },
      }),
      [const ToolResultEvent(id: 'f1', error: true)],
    );
    expect(
      translate({
        'type': 'error',
        'error': {'message': 'overloaded'},
      }),
      [const ErrorEvent(message: 'overloaded')],
    );
    expect(translate({'type': 'ping'}), isEmpty);
  });

  test('openai responses: reasoning, web search, function call pending', () async {
    final tracker = ActivityTracker();
    final seen = record(tracker);
    await followOpenAIResponses(
      streamOf<JsonMap>([
        {'type': 'response.created'},
        {
          'type': 'response.output_item.added',
          'item': {'type': 'reasoning'},
        },
        {'type': 'response.reasoning_summary_text.delta', 'delta': 'Looking up'},
        {
          'type': 'response.output_item.added',
          'item': {'type': 'web_search_call', 'id': 'ws'},
        },
        {
          'type': 'response.output_item.done',
          'item': {'type': 'web_search_call', 'id': 'ws'},
        },
        {
          'type': 'response.output_item.added',
          'item': {'type': 'message'},
        },
        {'type': 'response.output_text.delta', 'delta': 'Here is'},
        {
          'type': 'response.output_item.added',
          'item': {'type': 'function_call', 'name': 'read_file', 'call_id': 'c1'},
        },
        {'type': 'response.function_call_arguments.delta', 'delta': '{"path"'},
        {
          'type': 'response.completed',
          'response': {
            'output': [
              {'type': 'message'},
              {'type': 'function_call', 'name': 'read_file'},
            ],
          },
        },
      ]),
      tracker,
    );
    expect(seen, ['idle', 'thinking', 'tool:web_search', 'thinking', 'writing', 'tool:read_file']);
    expect(tracker.activity.kind, ToolKind.file);
  });

  test('openai responses: approval requests wait and completion without client calls is done', () async {
    final tracker = ActivityTracker();
    final seen = record(tracker);
    await followOpenAIResponses(
      streamOf<JsonMap>([
        {'type': 'response.created'},
        {
          'type': 'response.output_item.added',
          'item': {'type': 'mcp_approval_request', 'name': 'deploy_config', 'id': 'ap1'},
        },
        {
          'type': 'response.output_item.added',
          'item': {'type': 'message'},
        },
        {'type': 'response.output_text.delta', 'delta': 'Done.'},
        {
          'type': 'response.completed',
          'response': {
            'output': [
              {'type': 'message'},
            ],
          },
        },
      ]),
      tracker,
    );
    expect(seen, ['idle', 'thinking', 'waiting:deploy_config', 'writing', 'done']);
  });

  test('openai chat completions: reasoning then tool calls', () async {
    final tracker = ActivityTracker();
    final seen = record(tracker);
    await followChatCompletions(
      streamOf<JsonMap>([
        {
          'choices': [
            {
              'delta': {'reasoning_content': 'hmm'},
            },
          ],
        },
        {
          'choices': [
            {
              'delta': {'content': 'Let me check.'},
            },
          ],
        },
        {
          'choices': [
            {
              'delta': {
                'tool_calls': [
                  {
                    'id': '1',
                    'function': {'name': 'search_docs', 'arguments': ''},
                  },
                ],
              },
            },
          ],
        },
        {
          'choices': [
            {
              'delta': {
                'tool_calls': [
                  {
                    'function': {'arguments': '{"q":"x"}'},
                  },
                ],
              },
            },
          ],
        },
        {
          'choices': [
            {'delta': <String, Object?>{}, 'finish_reason': 'tool_calls'},
          ],
        },
      ]),
      tracker,
    );
    expect(seen, ['idle', 'thinking', 'writing', 'tool:search_docs']);
  });

  test('openai chat completions: a stream error marks the tracker', () async {
    final tracker = ActivityTracker();
    final stream = Stream<JsonMap>.error(Exception('reset'));
    await expectLater(followChatCompletions(stream, tracker), throwsException);
    expect(tracker.activity.phase, Phase.error);
  });
}
