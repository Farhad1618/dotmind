import 'phase.dart';
import 'tool_kind.dart';
import 'tools.dart';

final class Activity {
  const Activity(this.phase, {this.tool, this.kind, this.label, this.progress});

  factory Activity.usingTool(String name, {Map<String, ToolKind>? overrides, int? progress}) =>
      Activity(Phase.tool, tool: name, kind: classifyTool(name, overrides), progress: progress);

  static const Activity idle = Activity(Phase.idle);

  final Phase phase;
  final String? tool;
  final ToolKind? kind;
  final String? label;
  final int? progress;

  Activity withProgress(int value) => Activity(phase, tool: tool, kind: kind, label: label, progress: value);

  @override
  bool operator ==(Object other) =>
      other is Activity &&
      other.phase == phase &&
      other.tool == tool &&
      other.kind == kind &&
      other.label == label &&
      other.progress == progress;

  @override
  int get hashCode => Object.hash(phase, tool, kind, label, progress);

  @override
  String toString() {
    final parts = <String>[phase.name];
    if (tool != null) parts.add('tool: $tool');
    if (kind != null) parts.add('kind: ${kind!.name}');
    if (label != null) parts.add('label: $label');
    if (progress != null) parts.add('progress: $progress');
    return 'Activity(${parts.join(', ')})';
  }
}
