import '../core/agent_event.dart';
import '../core/tracker.dart';
import 'follow_stream.dart';
import 'json_access.dart';

final class ChatCompletionsTranslator {
  bool _started = false;

  List<AgentEvent> call(JsonMap chunk) {
    final out = <AgentEvent>[];
    if (!_started) {
      _started = true;
      out.add(const StartEvent());
    }
    final choices = jsonList(chunk['choices']);
    final choice = choices.isEmpty ? null : jsonMap(choices.first);
    final delta = jsonMap(choice?['delta']);
    final reasoning = _reasoning(delta);
    if (isFilled(reasoning)) out.add(ThinkingEvent(chars: reasoning!.length));
    for (final entry in jsonList(delta?['tool_calls'])) {
      final call = jsonMap(entry);
      final function = jsonMap(call?['function']);
      final name = jsonString(function, 'name');
      final arguments = jsonString(function, 'arguments');
      if (isFilled(name)) out.add(ToolEvent(name!, id: jsonString(call, 'id')));
      if (isFilled(arguments)) out.add(ToolInputEvent(chars: arguments!.length));
    }
    final content = jsonString(delta, 'content');
    if (isFilled(content)) out.add(TextEvent(chars: content!.length));
    final finish = jsonString(choice, 'finish_reason');
    if (isFilled(finish)) out.add(FinishEvent(pendingTools: finish == 'tool_calls'));
    return out;
  }

  String? _reasoning(Map<Object?, Object?>? delta) {
    final direct = delta?['reasoning'];
    if (direct != null) return direct is String ? direct : null;
    return jsonString(delta, 'reasoning_content');
  }
}

Future<ActivityTracker> followChatCompletions(Stream<JsonMap> stream, [ActivityTracker? tracker]) =>
    followStream(stream, ChatCompletionsTranslator().call, tracker);
