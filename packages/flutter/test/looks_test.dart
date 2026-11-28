import 'dart:typed_data';

import 'package:dotmind/dotmind.dart';
import 'package:flutter_test/flutter_test.dart';

const List<Scene> newScenes = [
  Scene.neural,
  Scene.magnifier,
  Scene.glyph,
  Scene.sort,
  Scene.rocket,
  Scene.verified,
  Scene.bug,
  Scene.blocks,
  Scene.scan,
];

Activity tool(ToolKind kind) => Activity(Phase.tool, kind: kind);

void main() {
  test('new tool kinds are recognised without changing older ones', () {
    const cases = {
      'translate_text': ToolKind.translate,
      'localizeStrings': ToolKind.translate,
      'i18n_sync': ToolKind.translate,
      'set_locale': ToolKind.translate,
      'deploy_service': ToolKind.deploy,
      'kubectl_apply': ToolKind.deploy,
      'helm_upgrade': ToolKind.deploy,
      'publish_release': ToolKind.deploy,
      'rollout_canary': ToolKind.deploy,
      'debugger_step': ToolKind.debug,
      'set_breakpoint': ToolKind.debug,
      'parse_traceback': ToolKind.debug,
      'inspect_element': ToolKind.debug,
      'inspect_page': ToolKind.browse,
      'i18n_lookup': ToolKind.search,
      'run_deploy_script': ToolKind.code,
      'get_weather': ToolKind.generic,
    };
    cases.forEach((name, kind) => expect(classifyTool(name), kind, reason: name));
  });

  test('new kinds have default labels', () {
    expect(labelFor(tool(ToolKind.translate)), 'Translating');
    expect(labelFor(tool(ToolKind.deploy)), 'Deploying');
    expect(labelFor(tool(ToolKind.debug)), 'Debugging');
  });

  test('every new pattern fills 64 finite values in range and changes over time', () {
    final out = Float32List(cellCount);
    for (final scene in newScenes) {
      expect(sceneColors[scene], isNotNull, reason: scene.name);
      final seen = <String>{};
      var lit = 0;
      for (final t in const [0.0, 0.3, 0.5, 1.7, 2.9, 4.1, 12.5, 400.0]) {
        for (final progress in const [0.0, 137.0]) {
          patternFor(scene)(t, out, PatternContext(energy: 0.8, progress: progress));
          for (final v in out) {
            expect(v.isFinite && v >= 0 && v <= 1.5, isTrue, reason: '${scene.name}@$t: $v');
          }
          if (out.any((v) => v > 0.5)) lit++;
          seen.add(out.map((v) => v.toStringAsFixed(2)).join(','));
        }
      }
      expect(seen.length, greaterThan(3), reason: '${scene.name} animates');
      expect(lit, greaterThanOrEqualTo(12), reason: '${scene.name} lights something most of the time');
    }
  });

  test('new patterns are deterministic', () {
    final a = Float32List(cellCount);
    final b = Float32List(cellCount);
    for (final scene in newScenes) {
      patternFor(scene)(7.77, a, PatternContext(energy: 0.8));
      patternFor(scene)(7.77, b, PatternContext(energy: 0.8));
      expect(a, b, reason: scene.name);
    }
  });

  test('the sort scene ends on an ascending staircase', () {
    final out = Float32List(cellCount);
    patternFor(Scene.sort)(0.16 * 38 + 0.05, out, PatternContext(energy: 0.8));
    final heights = [
      for (var x = 0; x < gridSize; x++)
        [for (var y = 0; y < gridSize; y++) out[y * gridSize + x]].where((v) => v > 0).length,
    ];
    expect(heights, [1, 2, 3, 4, 5, 6, 7, 8]);
  });

  test('a scene key names the state', () {
    expect(SceneKey.of(const Activity(Phase.thinking)).id, 'thinking');
    expect(SceneKey.of(const Activity(Phase.tool)).id, 'tool:generic');
    expect(SceneKey.of(tool(ToolKind.debug)).id, 'tool:debug');
    for (final key in SceneKey.values) {
      expect(SceneKey.parse(key.id), key);
      expect(defaultLabels[key.id], isNotNull, reason: key.id);
    }
    expect(SceneKey.parse('tool:nope'), isNull);
  });

  test('looks map states to scenes', () {
    expect(sceneFor(const Activity(Phase.thinking)), Scene.comet);
    expect(sceneFor(tool(ToolKind.translate)), Scene.glyph);
    expect(sceneFor(tool(ToolKind.deploy)), Scene.rocket);
    expect(sceneFor(tool(ToolKind.debug)), Scene.bug);

    expect(sceneFor(const Activity(Phase.thinking), look: Look.icons), Scene.neural);
    expect(sceneFor(tool(ToolKind.search), look: Look.icons), Scene.magnifier);
    expect(sceneFor(tool(ToolKind.translate), look: Look.icons), Scene.glyph);
    expect(sceneFor(tool(ToolKind.compute), look: Look.icons), Scene.sort);
    expect(sceneFor(tool(ToolKind.deploy), look: Look.icons), Scene.rocket);
    expect(sceneFor(const Activity(Phase.done), look: Look.icons), Scene.verified);
    expect(sceneFor(const Activity(Phase.writing), look: Look.icons), Scene.type);
    expect(sceneFor(tool(ToolKind.database), look: Look.icons), Scene.stack);

    expect(sceneFor(tool(ToolKind.debug), look: Look.pixel), Scene.bug);
    expect(sceneFor(tool(ToolKind.code), look: Look.pixel), Scene.blocks);
    expect(sceneFor(tool(ToolKind.search), look: Look.pixel), Scene.scan);
    expect(sceneFor(const Activity(Phase.thinking), look: Look.pixel), Scene.comet);
  });

  test('every look covers every state and carries its shape and aura', () {
    expect(classicScenes.keys.toSet(), SceneKey.values.toSet());
    for (final look in Look.values) {
      expect(looks[look], isNotNull, reason: look.name);
    }
    expect(lookDefinition(Look.pixel).shape, CellShape.square);
    expect(lookDefinition(Look.icons).shape, CellShape.dot);
    expect(lookDefinition(Look.classic).shape, CellShape.dot);
    expect(lookDefinition(Look.icons).aura, isTrue);
    expect(lookDefinition(Look.classic).aura, isFalse);
    expect(lookDefinition(Look.pixel).aura, isFalse);
  });

  test('scene overrides beat the look table and unknown looks fall back to classic', () {
    expect(
      sceneFor(const Activity(Phase.thinking), look: Look.icons, overrides: const {SceneKey.thinking: Scene.ember}),
      Scene.ember,
    );
    expect(
      sceneFor(tool(ToolKind.search), look: Look.pixel, overrides: const {SceneKey.toolSearch: Scene.magnifier}),
      Scene.magnifier,
    );
    expect(sceneFor(tool(ToolKind.file), overrides: const {SceneKey.toolFile: Scene.sort}), Scene.sort);
    expect(
      sceneFor(tool(ToolKind.search), look: Look.pixel, overrides: const {SceneKey.thinking: Scene.ember}),
      Scene.scan,
    );
    expect(Look.named('nope'), Look.classic);
    expect(Look.named(null), Look.classic);
    expect(Look.named('pixel'), Look.pixel);
    expect(sceneFor(const Activity(Phase.thinking), look: Look.named('nope')), Scene.comet);
  });

  test('shape geometry matches the spec', () {
    expect([CellShape.dot.size, CellShape.dot.corner, CellShape.dot.base], [0.68, 0.5, 0.14]);
    expect([CellShape.square.size, CellShape.square.corner, CellShape.square.base], [0.8, 0.22, 0.2]);
  });
}
