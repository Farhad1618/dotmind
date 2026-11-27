import 'activity.dart';
import 'phase.dart';
import 'scene.dart';
import 'tool_kind.dart';

Scene sceneForTool(ToolKind kind) => switch (kind) {
  ToolKind.search => Scene.radar,
  ToolKind.browse => Scene.globe,
  ToolKind.code => Scene.code,
  ToolKind.file => Scene.pages,
  ToolKind.database => Scene.stack,
  ToolKind.compute => Scene.prism,
  ToolKind.generic => Scene.circuit,
};

Scene sceneFor(Activity activity) => switch (activity.phase) {
  Phase.idle => Scene.breathe,
  Phase.thinking => Scene.comet,
  Phase.tool => sceneForTool(activity.kind ?? ToolKind.generic),
  Phase.writing => Scene.type,
  Phase.waiting => Scene.halo,
  Phase.error => Scene.cross,
  Phase.done => Scene.check,
};
