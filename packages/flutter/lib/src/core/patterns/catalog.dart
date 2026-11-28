import '../rgb.dart';
import '../scene.dart';
import 'ambient_patterns.dart' as ambient;
import 'icon_patterns.dart' as icon;
import 'pattern.dart';
import 'pixel_patterns.dart' as pixel;
import 'state_patterns.dart' as state;
import 'tool_patterns.dart' as tool;

Pattern patternFor(Scene scene) => switch (scene) {
  Scene.breathe => state.breathe,
  Scene.comet => state.comet,
  Scene.radar => tool.radar,
  Scene.globe => tool.globe,
  Scene.code => tool.code,
  Scene.pages => tool.pages,
  Scene.stack => tool.stack,
  Scene.prism => tool.prism,
  Scene.circuit => tool.circuit,
  Scene.type => state.type,
  Scene.halo => state.halo,
  Scene.cross => state.cross,
  Scene.check => state.check,
  Scene.ember => ambient.ember,
  Scene.orbit => ambient.orbit,
  Scene.serpent => ambient.serpent,
  Scene.pulse => ambient.pulse,
  Scene.neural => icon.neural,
  Scene.magnifier => icon.magnifier,
  Scene.glyph => icon.glyph,
  Scene.sort => icon.sort,
  Scene.rocket => icon.rocket,
  Scene.verified => icon.verified,
  Scene.bug => pixel.bug,
  Scene.blocks => pixel.blocks,
  Scene.scan => pixel.scan,
};

const Map<Scene, Rgb> sceneColors = {
  Scene.breathe: Rgb(160, 160, 172),
  Scene.comet: Rgb(143, 125, 255),
  Scene.radar: Rgb(61, 123, 255),
  Scene.globe: Rgb(74, 168, 255),
  Scene.code: Rgb(255, 162, 31),
  Scene.pages: Rgb(56, 210, 190),
  Scene.stack: Rgb(255, 122, 26),
  Scene.prism: Rgb(255, 190, 60),
  Scene.circuit: Rgb(74, 168, 255),
  Scene.type: Rgb(228, 228, 236),
  Scene.halo: Rgb(255, 176, 32),
  Scene.cross: Rgb(255, 74, 62),
  Scene.check: Rgb(70, 220, 130),
  Scene.ember: Rgb(255, 74, 42),
  Scene.orbit: Rgb(61, 123, 255),
  Scene.serpent: Rgb(154, 107, 255),
  Scene.pulse: Rgb(255, 122, 26),
  Scene.neural: Rgb(150, 104, 255),
  Scene.magnifier: Rgb(64, 196, 236),
  Scene.glyph: Rgb(255, 214, 64),
  Scene.sort: Rgb(255, 120, 32),
  Scene.rocket: Rgb(236, 72, 196),
  Scene.verified: Rgb(64, 214, 140),
  Scene.bug: Rgb(72, 164, 255),
  Scene.blocks: Rgb(255, 150, 40),
  Scene.scan: Rgb(255, 82, 72),
};

Rgb sceneColor(Scene scene) => sceneColors[scene]!;
