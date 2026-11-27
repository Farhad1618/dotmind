import '../core/agent_event.dart';
import '../core/tracker.dart';

typedef Translator<E> = List<AgentEvent> Function(E event);

Future<ActivityTracker> followStream<E>(Stream<E> stream, Translator<E> translate, [ActivityTracker? tracker]) async {
  final target = tracker ?? ActivityTracker();
  try {
    await for (final event in stream) {
      target.pushAll(translate(event));
    }
  } catch (error) {
    target.push(ErrorEvent(message: error.toString()));
    rethrow;
  }
  return target;
}
