import 'cell_shape.dart';
import 'look.dart';
import 'scene.dart';
import 'scene_key.dart';

final class LookDefinition {
  const LookDefinition({required this.scenes, required this.shape, required this.aura});

  final Map<SceneKey, Scene> scenes;
  final CellShape shape;
  final bool aura;
}

const Map<SceneKey, Scene> classicScenes = {
  SceneKey.idle: Scene.breathe,
  SceneKey.thinking: Scene.comet,
  SceneKey.writing: Scene.type,
  SceneKey.waiting: Scene.halo,
  SceneKey.error: Scene.cross,
  SceneKey.done: Scene.check,
  SceneKey.toolSearch: Scene.radar,
  SceneKey.toolBrowse: Scene.globe,
  SceneKey.toolCode: Scene.code,
  SceneKey.toolFile: Scene.pages,
  SceneKey.toolDatabase: Scene.stack,
  SceneKey.toolCompute: Scene.prism,
  SceneKey.toolTranslate: Scene.glyph,
  SceneKey.toolDeploy: Scene.rocket,
  SceneKey.toolDebug: Scene.bug,
  SceneKey.toolGeneric: Scene.circuit,
};

const Map<Look, LookDefinition> looks = {
  Look.classic: LookDefinition(scenes: {}, shape: CellShape.dot, aura: false),
  Look.icons: LookDefinition(
    scenes: {
      SceneKey.thinking: Scene.neural,
      SceneKey.done: Scene.verified,
      SceneKey.toolSearch: Scene.magnifier,
      SceneKey.toolTranslate: Scene.glyph,
      SceneKey.toolCompute: Scene.sort,
      SceneKey.toolDeploy: Scene.rocket,
    },
    shape: CellShape.dot,
    aura: true,
  ),
  Look.pixel: LookDefinition(
    scenes: {SceneKey.toolDebug: Scene.bug, SceneKey.toolCode: Scene.blocks, SceneKey.toolSearch: Scene.scan},
    shape: CellShape.square,
    aura: false,
  ),
};

LookDefinition lookDefinition(Look look) => looks[look]!;
