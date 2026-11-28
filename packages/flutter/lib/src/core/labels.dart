import 'activity.dart';
import 'phase.dart';
import 'tool_kind.dart';
import 'tools.dart';

String phaseLabelKey(Phase phase) => phase.name;

String toolLabelKey(ToolKind kind) => 'tool:${kind.name}';

const Map<String, String> defaultLabels = {
  'idle': 'Ready',
  'thinking': 'Thinking',
  'writing': 'Writing',
  'waiting': 'Waiting for you',
  'error': 'Something went wrong',
  'done': 'Done',
  'tool:search': 'Searching',
  'tool:browse': 'Browsing',
  'tool:code': 'Running code',
  'tool:file': 'Reading files',
  'tool:database': 'Querying data',
  'tool:compute': 'Calculating',
  'tool:translate': 'Translating',
  'tool:deploy': 'Deploying',
  'tool:debug': 'Debugging',
  'tool:generic': 'Using a tool',
};

String labelFor(Activity activity, [Map<String, String> labels = const {}]) {
  final own = activity.label;
  if (own != null && own.isNotEmpty) return own;
  String pick(String key) => labels[key] ?? defaultLabels[key]!;
  if (activity.phase == Phase.tool) {
    final kind = activity.kind ?? ToolKind.generic;
    final tool = activity.tool;
    final genericOverride = labels[toolLabelKey(ToolKind.generic)];
    final hasOverride = genericOverride != null && genericOverride.isNotEmpty;
    if (kind == ToolKind.generic && tool != null && tool.isNotEmpty && !hasOverride) {
      return 'Using ${humanizeTool(tool)}';
    }
    return pick(toolLabelKey(kind));
  }
  return pick(phaseLabelKey(activity.phase));
}
