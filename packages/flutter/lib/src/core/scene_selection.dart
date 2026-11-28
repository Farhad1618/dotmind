import 'activity.dart';
import 'look.dart';
import 'looks.dart';
import 'scene.dart';
import 'scene_key.dart';
import 'tool_kind.dart';

Scene sceneForTool(ToolKind kind) => classicScenes[SceneKey.forTool(kind)]!;

Scene sceneFor(Activity activity, {Look look = Look.classic, Map<SceneKey, Scene> overrides = const {}}) {
  final key = SceneKey.of(activity);
  return overrides[key] ?? lookDefinition(look).scenes[key] ?? classicScenes[key]!;
}
