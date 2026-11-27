import 'dart:typed_data';

import 'package:dotmind/dotmind.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('tool names map to the kind of work they do', () {
    const cases = {
      'web_search': ToolKind.search,
      'file_search': ToolKind.search,
      'searchDocs': ToolKind.search,
      'run_sql': ToolKind.database,
      'query_clickhouse': ToolKind.database,
      'web_fetch': ToolKind.browse,
      'navigate': ToolKind.browse,
      'bash': ToolKind.code,
      'code_interpreter': ToolKind.code,
      'str_replace_based_edit_tool': ToolKind.file,
      'read_file': ToolKind.file,
      'calculate_margin': ToolKind.compute,
      'get_weather': ToolKind.generic,
    };
    cases.forEach((name, kind) => expect(classifyTool(name), kind, reason: name));
    expect(classifyTool('get_weather', {'get_weather': ToolKind.browse}), ToolKind.browse);
    expect(classifyTool(null), ToolKind.generic);
    expect(toolTokens('searchDocsV2'), ['search', 'docs', 'v2']);
  });

  test('labels follow the activity', () {
    expect(labelFor(const Activity(Phase.thinking)), 'Thinking');
    expect(labelFor(const Activity(Phase.tool, kind: ToolKind.search)), 'Searching');
    expect(labelFor(const Activity(Phase.tool, tool: 'get_weather', kind: ToolKind.generic)), 'Using get weather');
    expect(
      labelFor(const Activity(Phase.tool, kind: ToolKind.search), {toolLabelKey(ToolKind.search): 'Buscando'}),
      'Buscando',
    );
    expect(labelFor(const Activity(Phase.writing, label: 'Drafting reply')), 'Drafting reply');
    expect(
      labelFor(const Activity(Phase.tool, tool: 'get_weather', kind: ToolKind.generic), {
        toolLabelKey(ToolKind.generic): 'Working',
      }),
      'Working',
    );
  });

  test('each phase picks a scene', () {
    expect(sceneFor(const Activity(Phase.thinking)), Scene.comet);
    expect(sceneFor(const Activity(Phase.tool, kind: ToolKind.search)), Scene.radar);
    expect(sceneFor(const Activity(Phase.tool, kind: ToolKind.database)), Scene.stack);
    expect(sceneFor(const Activity(Phase.writing)), Scene.type);
    expect(sceneFor(const Activity(Phase.done)), Scene.check);
  });

  test('every pattern fills 64 finite values in range', () {
    final out = Float32List(cellCount);
    for (final scene in Scene.values) {
      for (final t in const [0.0, 0.3, 1.7, 12.5, 400.0]) {
        patternFor(scene)(t, out, PatternContext(energy: 0.8, progress: 137));
        for (final v in out) {
          expect(v.isFinite && v >= 0 && v <= 1.6, isTrue, reason: '${scene.name}@$t: $v');
        }
      }
    }
  });

  test('the writing scene lights more dots as text arrives', () {
    int lit(double progress) {
      final out = Float32List(cellCount);
      patternFor(Scene.type)(0.1, out, PatternContext(energy: 0.5, progress: progress));
      return out.where((v) => v > 0.3).length;
    }

    expect(lit(0), lessThan(lit(40)));
    expect(lit(40), lessThan(lit(120)));
  });

  test('faster text makes the renderer livelier', () {
    final r = DotRenderer(Scene.type);
    var p = 0;
    r.feed(p);
    for (var i = 0; i < 60; i++) {
      r.step(1 / 60);
      r.feed(p += 1);
    }
    final slow = r.level;
    for (var i = 0; i < 60; i++) {
      r.step(1 / 60);
      r.feed(p += 8);
    }
    expect(r.level, greaterThan(slow));
    for (var i = 0; i < 180; i++) {
      r.step(1 / 60);
    }
    expect(r.level, lessThan(0.5));
  });

  test('switching scenes cross-fades instead of cutting', () {
    final r = DotRenderer(Scene.check);
    r.step(2);
    final before = Float32List.fromList(r.sample());
    r.show(Scene.cross);
    r.step(0.1);
    final mid = r.sample();
    final target = Float32List(cellCount);
    patternFor(Scene.cross)(0.1 * (0.6 + 0.6 * r.level), target, PatternContext(energy: r.level));
    var differsFromBoth = false;
    for (var i = 0; i < cellCount; i++) {
      if ((mid[i] - before[i]).abs() > 0.05 && (mid[i] - target[i]).abs() > 0.05) differsFromBoth = true;
    }
    expect(differsFromBoth, isTrue);
    expect(r.isBlending, isTrue);
    r.step(blendSeconds);
    expect(r.isBlending, isFalse);
  });

  test('the colour blends between scenes and settles on the new one', () {
    final r = DotRenderer(Scene.check);
    r.show(Scene.cross);
    r.step(blendSeconds / 2);
    final mid = r.color();
    expect(mid, isNot(sceneColor(Scene.cross)));
    final out = Float64List(3);
    r.writeColor(out);
    expect([out[0], out[1], out[2]], [mid.r, mid.g, mid.b]);
    r.step(1);
    expect(r.color(), sceneColor(Scene.cross));
  });

  test('a scene counts progress from when it was shown', () {
    final r = DotRenderer(Scene.comet);
    r.feed(400);
    r.show(Scene.type, instant: true);
    final lit = r.sample().where((v) => v > 0.3).length;
    expect(lit, 1);
    r.feed(440);
    expect(r.sample().where((v) => v > 0.3).length, greaterThan(lit));
  });

  test('sampling into a buffer reuses it', () {
    final r = DotRenderer(Scene.radar);
    final buffer = Float32List(cellCount);
    expect(identical(r.sample(buffer), buffer), isTrue);
  });
}
