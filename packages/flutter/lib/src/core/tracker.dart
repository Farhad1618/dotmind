import 'package:flutter/foundation.dart';

import 'activity.dart';
import 'agent_event.dart';
import 'phase.dart';
import 'tool_kind.dart';
import 'tools.dart';

typedef ActivityListener = void Function(Activity activity);

class ActivityTracker extends ChangeNotifier implements ValueListenable<Activity> {
  ActivityTracker({this.tools});

  final Map<String, ToolKind>? tools;
  final Map<String, String> _openTools = {};
  Activity _state = const Activity(Phase.idle, progress: 0);

  @override
  Activity get value => _state;

  Activity get activity => _state;

  VoidCallback subscribe(ActivityListener listener) {
    void relay() => listener(_state);
    addListener(relay);
    listener(_state);
    return () => removeListener(relay);
  }

  void reset() {
    _openTools.clear();
    _set(const Activity(Phase.idle, progress: 0));
  }

  void pushAll(Iterable<AgentEvent> events) {
    for (final event in events) {
      push(event);
    }
  }

  void push(AgentEvent event) {
    final progress = _state.progress ?? 0;
    switch (event) {
      case StartEvent():
        _openTools.clear();
        _set(Activity(Phase.thinking, progress: progress));
      case ThinkingEvent(:final chars):
        _set(Activity(Phase.thinking, progress: progress + (chars ?? 0)));
      case ToolEvent(:final name, :final id):
        if (id != null) _openTools[id] = name;
        _set(_toolActivity(Phase.tool, name, progress));
      case ToolInputEvent(:final chars):
        _set(_state.withProgress(progress + (chars ?? 0)));
      case ToolResultEvent(:final id):
        if (id != null) _openTools.remove(id);
        _set(Activity(Phase.thinking, progress: progress));
      case TextEvent(:final chars):
        _set(Activity(Phase.writing, progress: progress + (chars ?? 0)));
      case ApprovalEvent(:final name):
        _set(_toolActivity(Phase.waiting, name, progress));
      case ErrorEvent():
        _set(Activity(Phase.error, progress: progress));
      case FinishEvent(:final pendingTools):
        if (!pendingTools) {
          _set(Activity(Phase.done, progress: progress));
          return;
        }
        final last = _openTools.isEmpty ? _state.tool : _openTools.values.last;
        _set(_toolActivity(Phase.tool, last, progress));
    }
  }

  Activity _toolActivity(Phase phase, String? name, int progress) =>
      Activity(phase, tool: name, kind: classifyTool(name, tools), progress: progress);

  void _set(Activity next) {
    final prev = _state;
    if (prev.phase == next.phase &&
        prev.tool == next.tool &&
        prev.kind == next.kind &&
        prev.progress == next.progress) {
      return;
    }
    _state = next;
    notifyListeners();
  }
}
