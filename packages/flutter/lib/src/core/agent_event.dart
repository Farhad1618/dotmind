sealed class AgentEvent {
  const AgentEvent();

  const factory AgentEvent.start() = StartEvent;
  const factory AgentEvent.thinking({int? chars}) = ThinkingEvent;
  const factory AgentEvent.tool(String name, {String? id}) = ToolEvent;
  const factory AgentEvent.toolInput({int? chars}) = ToolInputEvent;
  const factory AgentEvent.toolResult({String? id, bool error}) = ToolResultEvent;
  const factory AgentEvent.text({int? chars}) = TextEvent;
  const factory AgentEvent.approval({String? name, String? id}) = ApprovalEvent;
  const factory AgentEvent.error({String? message}) = ErrorEvent;
  const factory AgentEvent.finish({bool pendingTools}) = FinishEvent;
}

final class StartEvent extends AgentEvent {
  const StartEvent();

  @override
  bool operator ==(Object other) => other is StartEvent;

  @override
  int get hashCode => (StartEvent).hashCode;

  @override
  String toString() => 'StartEvent()';
}

final class ThinkingEvent extends AgentEvent {
  const ThinkingEvent({this.chars});

  final int? chars;

  @override
  bool operator ==(Object other) => other is ThinkingEvent && other.chars == chars;

  @override
  int get hashCode => Object.hash(ThinkingEvent, chars);

  @override
  String toString() => 'ThinkingEvent(chars: $chars)';
}

final class ToolEvent extends AgentEvent {
  const ToolEvent(this.name, {this.id});

  final String name;
  final String? id;

  @override
  bool operator ==(Object other) => other is ToolEvent && other.name == name && other.id == id;

  @override
  int get hashCode => Object.hash(ToolEvent, name, id);

  @override
  String toString() => 'ToolEvent($name, id: $id)';
}

final class ToolInputEvent extends AgentEvent {
  const ToolInputEvent({this.chars});

  final int? chars;

  @override
  bool operator ==(Object other) => other is ToolInputEvent && other.chars == chars;

  @override
  int get hashCode => Object.hash(ToolInputEvent, chars);

  @override
  String toString() => 'ToolInputEvent(chars: $chars)';
}

final class ToolResultEvent extends AgentEvent {
  const ToolResultEvent({this.id, this.error = false});

  final String? id;
  final bool error;

  @override
  bool operator ==(Object other) => other is ToolResultEvent && other.id == id && other.error == error;

  @override
  int get hashCode => Object.hash(ToolResultEvent, id, error);

  @override
  String toString() => 'ToolResultEvent(id: $id, error: $error)';
}

final class TextEvent extends AgentEvent {
  const TextEvent({this.chars});

  final int? chars;

  @override
  bool operator ==(Object other) => other is TextEvent && other.chars == chars;

  @override
  int get hashCode => Object.hash(TextEvent, chars);

  @override
  String toString() => 'TextEvent(chars: $chars)';
}

final class ApprovalEvent extends AgentEvent {
  const ApprovalEvent({this.name, this.id});

  final String? name;
  final String? id;

  @override
  bool operator ==(Object other) => other is ApprovalEvent && other.name == name && other.id == id;

  @override
  int get hashCode => Object.hash(ApprovalEvent, name, id);

  @override
  String toString() => 'ApprovalEvent(name: $name, id: $id)';
}

final class ErrorEvent extends AgentEvent {
  const ErrorEvent({this.message});

  final String? message;

  @override
  bool operator ==(Object other) => other is ErrorEvent && other.message == message;

  @override
  int get hashCode => Object.hash(ErrorEvent, message);

  @override
  String toString() => 'ErrorEvent(message: $message)';
}

final class FinishEvent extends AgentEvent {
  const FinishEvent({this.pendingTools = false});

  final bool pendingTools;

  @override
  bool operator ==(Object other) => other is FinishEvent && other.pendingTools == pendingTools;

  @override
  int get hashCode => Object.hash(FinishEvent, pendingTools);

  @override
  String toString() => 'FinishEvent(pendingTools: $pendingTools)';
}
