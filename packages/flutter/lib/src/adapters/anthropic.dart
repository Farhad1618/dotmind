import '../core/agent_event.dart';
import '../core/tracker.dart';
import 'follow_stream.dart';
import 'json_access.dart';

const Set<String> _toolCallBlocks = {'tool_use', 'server_tool_use', 'mcp_tool_use'};
const Set<String> _pendingStops = {'tool_use', 'pause_turn'};

bool _resultFailed(Map<Object?, Object?> block) {
  if (block['is_error'] == true) return true;
  final kind = jsonString(jsonMap(block['content']), 'type');
  return kind != null && kind.endsWith('error');
}

final class AnthropicTranslator {
  String? _stopReason;

  List<AgentEvent> call(JsonMap event) => switch (event['type']) {
    'message_start' => _messageStart(),
    'content_block_start' => _blockStart(jsonMap(event['content_block'])),
    'content_block_delta' => _blockDelta(jsonMap(event['delta'])),
    'message_delta' => _messageDelta(jsonMap(event['delta'])),
    'message_stop' => [FinishEvent(pendingTools: _stopReason != null && _pendingStops.contains(_stopReason))],
    'error' => [ErrorEvent(message: jsonString(jsonMap(event['error']), 'message'))],
    _ => const [],
  };

  List<AgentEvent> _messageStart() {
    _stopReason = null;
    return const [StartEvent()];
  }

  List<AgentEvent> _blockStart(Map<Object?, Object?>? block) {
    final type = jsonString(block, 'type');
    if (block == null || type == null) return const [];
    if (type == 'thinking' || type == 'redacted_thinking') return const [ThinkingEvent()];
    if (type == 'text') return const [TextEvent(chars: 0)];
    final name = jsonString(block, 'name');
    if (_toolCallBlocks.contains(type) && isFilled(name)) {
      return [ToolEvent(name!, id: jsonString(block, 'id'))];
    }
    if (type.endsWith('_tool_result')) {
      return [ToolResultEvent(id: jsonString(block, 'tool_use_id'), error: _resultFailed(block))];
    }
    return const [];
  }

  List<AgentEvent> _blockDelta(Map<Object?, Object?>? delta) => switch (jsonString(delta, 'type')) {
    'thinking_delta' => [ThinkingEvent(chars: jsonLength(delta, 'thinking'))],
    'text_delta' => [TextEvent(chars: jsonLength(delta, 'text'))],
    'input_json_delta' => [ToolInputEvent(chars: jsonLength(delta, 'partial_json'))],
    _ => const [],
  };

  List<AgentEvent> _messageDelta(Map<Object?, Object?>? delta) {
    _stopReason = jsonString(delta, 'stop_reason') ?? _stopReason;
    return const [];
  }
}

Future<ActivityTracker> followAnthropicStream(Stream<JsonMap> stream, [ActivityTracker? tracker]) =>
    followStream(stream, AnthropicTranslator().call, tracker);
