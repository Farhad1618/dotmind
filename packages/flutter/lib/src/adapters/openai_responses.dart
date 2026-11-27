import '../core/agent_event.dart';
import '../core/tracker.dart';
import 'follow_stream.dart';
import 'json_access.dart';

const Map<String, String> _serverTools = {
  'web_search_call': 'web_search',
  'file_search_call': 'file_search',
  'code_interpreter_call': 'code_interpreter',
  'computer_call': 'computer',
  'image_generation_call': 'image_generation',
  'local_shell_call': 'shell',
  'shell_call': 'shell',
};

const Set<String> _clientCalls = {
  'function_call',
  'custom_tool_call',
  'local_shell_call',
  'shell_call',
  'computer_call',
};

const Set<String> _namedCalls = {'function_call', 'custom_tool_call', 'mcp_call'};

String? _toolName(Map<Object?, Object?> item, String type) =>
    _namedCalls.contains(type) ? jsonString(item, 'name') : _serverTools[type];

String? _callId(Map<Object?, Object?> item) => jsonString(item, 'call_id') ?? jsonString(item, 'id');

final class OpenAIResponsesTranslator {
  List<AgentEvent> call(JsonMap event) {
    final item = jsonMap(event['item']);
    return switch (event['type']) {
      'response.created' => const [StartEvent()],
      'response.output_item.added' => _added(item),
      'response.output_item.done' => _done(item),
      'response.reasoning_summary_text.delta' ||
      'response.reasoning_text.delta' => [ThinkingEvent(chars: jsonLength(event, 'delta'))],
      'response.output_text.delta' || 'response.refusal.delta' => [TextEvent(chars: jsonLength(event, 'delta'))],
      'response.function_call_arguments.delta' ||
      'response.custom_tool_call_input.delta' ||
      'response.mcp_call_arguments.delta' => [ToolInputEvent(chars: jsonLength(event, 'delta'))],
      'response.completed' ||
      'response.incomplete' => [FinishEvent(pendingTools: _hasClientCall(jsonMap(event['response'])))],
      'response.failed' || 'error' => [ErrorEvent(message: jsonString(event, 'message'))],
      _ => const [],
    };
  }

  List<AgentEvent> _added(Map<Object?, Object?>? item) {
    final type = jsonString(item, 'type');
    if (item == null || type == null) return const [];
    if (type == 'reasoning') return const [ThinkingEvent()];
    if (type == 'message') return const [TextEvent(chars: 0)];
    if (type == 'mcp_approval_request') {
      return [ApprovalEvent(name: jsonString(item, 'name'), id: jsonString(item, 'id'))];
    }
    final name = _toolName(item, type);
    return isFilled(name) ? [ToolEvent(name!, id: _callId(item))] : const [];
  }

  List<AgentEvent> _done(Map<Object?, Object?>? item) {
    final type = jsonString(item, 'type');
    if (item == null || type == null) return const [];
    if (_serverTools.containsKey(type) && !_clientCalls.contains(type)) {
      return [ToolResultEvent(id: jsonString(item, 'id'))];
    }
    if (type == 'mcp_call') return [ToolResultEvent(id: _callId(item))];
    return const [];
  }

  bool _hasClientCall(Map<Object?, Object?>? response) =>
      jsonList(response?['output']).any((output) => _clientCalls.contains(jsonString(jsonMap(output), 'type')));
}

Future<ActivityTracker> followOpenAIResponses(Stream<JsonMap> stream, [ActivityTracker? tracker]) =>
    followStream(stream, OpenAIResponsesTranslator().call, tracker);
