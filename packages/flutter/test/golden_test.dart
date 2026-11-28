import 'dart:typed_data';

import 'package:dotmind/dotmind.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/golden.dart';

void expectValues(List<double> actual, List<double> expected, double tolerance, String reason) {
  expect(actual.length, expected.length, reason: reason);
  for (var i = 0; i < expected.length; i++) {
    expect(actual[i], closeTo(expected[i], tolerance), reason: '$reason cell $i');
  }
}

void main() {
  final golden = Golden.load();
  final tolerance = golden.tolerance;

  test('every golden frame matches the reference', () {
    final frames = golden.section('frames');
    expect(frames, hasLength(Scene.values.length * 8));
    final out = Float32List(cellCount);
    final perScene = <Scene, int>{};
    for (final frame in frames) {
      final scene = sceneNamed(frame['scene']);
      perScene[scene] = (perScene[scene] ?? 0) + 1;
      final t = (frame['t']! as num).toDouble();
      final ctx = PatternContext(
        energy: (frame['energy']! as num).toDouble(),
        progress: (frame['progress']! as num).toDouble(),
      );
      patternFor(scene)(t, out, ctx);
      expectValues(out, numbers(frame['values']), tolerance, '${scene.name}@$t/${ctx.progress}');
    }
    expect(perScene, {for (final scene in Scene.values) scene: 8});
  });

  test('every golden tool name maps to the same kind', () {
    final tools = golden.section('tools');
    expect(tools, isNotEmpty);
    final kinds = <String>{};
    for (final entry in tools) {
      final name = entry['name']! as String;
      kinds.add(entry['kind']! as String);
      expect(classifyTool(name).name, entry['kind'], reason: name);
    }
    expect(kinds, {for (final kind in ToolKind.values) kind.name});
  });

  test('every golden activity picks the same scene and label', () {
    final scenes = golden.section('scenes');
    expect(scenes, isNotEmpty);
    for (final entry in scenes) {
      final activity = activityFrom(entry['activity']! as Map<String, Object?>);
      expect(sceneFor(activity).name, entry['scene'], reason: '$activity');
      expect(labelFor(activity), entry['label'], reason: '$activity');
    }
  });

  test('the energy curve and sampled frames match the reference', () {
    final samples = golden.section('energy');
    expect(samples, hasLength(12));
    final renderer = DotRenderer(Scene.type);
    final out = Float32List(cellCount);
    var progress = 0;
    var next = 0;
    renderer.feed(progress);
    for (var i = 0; i < 240; i++) {
      renderer.step(1 / 60);
      if (i < 120) {
        progress += i < 60 ? 1 : 8;
        renderer.feed(progress);
      }
      if (i % 20 == 19) {
        final sample = samples[next++];
        expect(sample['frame'], i + 1);
        final reason = 'frame ${i + 1}';
        expect(renderer.level, closeTo((sample['energy']! as num).toDouble(), tolerance), reason: reason);
        expectValues(renderer.sample(out), numbers(sample['values']), tolerance, reason);
      }
    }
    expect(next, samples.length);
  });

  test('every golden scene key picks the same scene and label in every look', () {
    final entries = golden.section('looks');
    expect(entries, hasLength(SceneKey.values.length * Look.values.length));
    final covered = <(SceneKey, Look)>{};
    for (final entry in entries) {
      final activity = activityFrom(entry['activity']! as Map<String, Object?>);
      final look = Look.values.byName(entry['look']! as String);
      covered.add((SceneKey.of(activity), look));
      expect(sceneFor(activity, look: look).name, entry['scene'], reason: '$activity in ${look.name}');
      expect(sceneFor(activity, look: Look.named(entry['look']! as String)).name, entry['scene']);
      expect(labelFor(activity), entry['label'], reason: '$activity in ${look.name}');
    }
    expect(covered, hasLength(entries.length));
  });
}
