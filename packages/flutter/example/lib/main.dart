import 'dart:async';

import 'package:dotmind/dotmind.dart';
import 'package:material_ui/material_ui.dart';

void main() => runApp(const DotMindGallery());

abstract final class _Palette {
  static const stage = Color(0xFF121213);
  static const stageHigh = Color(0xFF1B1B1E);
  static const panel = Color(0xFF0D0D0E);
  static const rule = Color(0xFF232327);
  static const ink = Color(0xFFECECEF);
  static const inkDim = Color(0xFF8A8A92);
  static const inkFaint = Color(0xFF55555C);
  static const chip = Color(0xFF1A1A1D);
  static const chipOn = Color(0xFF26263A);
}

const List<String> _mono = ['Menlo', 'Roboto Mono', 'monospace'];

const TextStyle _eyebrow = TextStyle(
  fontFamily: 'Menlo',
  fontFamilyFallback: _mono,
  fontSize: 11,
  height: 1,
  letterSpacing: 2,
  color: _Palette.inkFaint,
);

const TextStyle _caption = TextStyle(
  fontFamily: 'Menlo',
  fontFamilyFallback: _mono,
  fontSize: 11,
  height: 1.4,
  color: _Palette.inkFaint,
);

const TextStyle _body = TextStyle(fontSize: 15, height: 1.55, letterSpacing: 0, color: _Palette.inkDim);

const List<Activity> _states = [
  Activity(Phase.thinking),
  Activity(Phase.tool, tool: 'web_search'),
  Activity(Phase.tool, tool: 'web_fetch'),
  Activity(Phase.tool, tool: 'bash'),
  Activity(Phase.tool, tool: 'read_file'),
  Activity(Phase.tool, tool: 'run_sql'),
  Activity(Phase.tool, tool: 'calculate_margin'),
  Activity(Phase.tool, tool: 'translate_text'),
  Activity(Phase.tool, tool: 'deploy_service'),
  Activity(Phase.tool, tool: 'set_breakpoint'),
  Activity(Phase.tool, tool: 'get_weather'),
  Activity(Phase.writing),
  Activity(Phase.waiting, tool: 'deploy_config'),
  Activity(Phase.error),
  Activity(Phase.done),
];

const List<Scene> _ambient = [
  Scene.ember,
  Scene.orbit,
  Scene.prism,
  Scene.serpent,
  Scene.circuit,
  Scene.pulse,
  Scene.comet,
  Scene.halo,
];

const List<Scene> _iconScenes = [Scene.neural, Scene.magnifier, Scene.glyph, Scene.sort, Scene.rocket, Scene.verified];

const List<Scene> _pixelScenes = [Scene.bug, Scene.blocks, Scene.scan];

const Map<Look, String> _lookBlurbs = {
  Look.classic: 'Round dots, no glow. The scenes the indicator started with.',
  Look.icons: 'Pictures for the big moments: a firing network while it thinks, a magnifier while it searches.',
  Look.pixel: 'Square cells and arcade sprites: a bug while it debugs, falling blocks while code runs.',
};

String _describe(Activity activity) {
  final tool = activity.tool;
  return tool == null ? 'phase="${activity.phase.name}"' : 'phase="${activity.phase.name}" tool="$tool"';
}

class DotMindGallery extends StatelessWidget {
  const DotMindGallery({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'dotmind',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(brightness: Brightness.dark, scaffoldBackgroundColor: _Palette.stage),
    home: const GalleryPage(),
  );
}

class GalleryPage extends StatefulWidget {
  const GalleryPage({super.key});

  @override
  State<GalleryPage> createState() => _GalleryPageState();
}

class _GalleryPageState extends State<GalleryPage> {
  Look _look = Look.classic;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: DecoratedBox(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(-0.6, -1),
          radius: 1.4,
          colors: [_Palette.stageHigh, _Palette.stage],
          stops: [0, 0.6],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 28, 20, 48),
          children: [
            const _Header(),
            const SizedBox(height: 32),
            _LookSwitch(look: _look, onChanged: (look) => setState(() => _look = look)),
            const SizedBox(height: 18),
            LiveTurn(look: _look),
            const SizedBox(height: 48),
            const _Section(
              title: 'Every state',
              blurb: 'The tool name picks the picture: web_search sweeps, run_sql lights disks, bash types.',
            ),
            _CellGrid(
              children: [
                for (final activity in _states)
                  _Cell(
                    caption: _describe(activity),
                    child: DotMind(activity: activity, look: _look, size: 34),
                  ),
              ],
            ),
            const SizedBox(height: 48),
            const _Section(
              title: 'Icons',
              blurb: 'The scenes of the icons look, with the aura glowing in each scene colour.',
            ),
            _CellGrid(
              children: [
                for (final scene in _iconScenes)
                  _Cell(
                    caption: 'scene="${scene.name}"',
                    child: DotMind(scene: scene, look: Look.icons, label: _labelFor(scene), size: 34),
                  ),
              ],
            ),
            const SizedBox(height: 48),
            const _Section(title: 'Pixel', blurb: 'The scenes of the pixel look, drawn in square cells.'),
            _CellGrid(
              children: [
                for (final scene in _pixelScenes)
                  _Cell(
                    caption: 'scene="${scene.name}"',
                    child: DotMind(scene: scene, look: Look.pixel, label: _labelFor(scene), size: 34),
                  ),
              ],
            ),
            const SizedBox(height: 48),
            const _Section(title: 'The original eight', blurb: 'Fixed scenes for when you only need a loader.'),
            _CellGrid(
              children: [
                for (final scene in _ambient)
                  _Cell(
                    caption: 'scene="${scene.name}"',
                    child: DotMind(scene: scene, label: 'Thinking', size: 34),
                  ),
              ],
            ),
            const SizedBox(height: 40),
            const Wrap(
              spacing: 14,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text('Inline, without the pill', style: _body),
                DotMind(
                  activity: Activity(Phase.thinking),
                  variant: DotMindVariant.bare,
                  size: 18,
                  style: DotMindStyle(textStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, height: 1.2)),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

String _labelFor(Scene scene) => switch (scene) {
  Scene.neural => 'Thinking',
  Scene.magnifier || Scene.scan => 'Searching',
  Scene.glyph => 'Translating',
  Scene.sort => 'Calculating',
  Scene.rocket => 'Deploying',
  Scene.verified => 'Done',
  Scene.bug => 'Debugging',
  Scene.blocks => 'Running code',
  _ => scene.name,
};

class _LookSwitch extends StatelessWidget {
  const _LookSwitch({required this.look, required this.onChanged});

  final Look look;
  final ValueChanged<Look> onChanged;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text('LOOK', style: _eyebrow),
      const SizedBox(height: 12),
      SegmentedButton<Look>(
        segments: [for (final look in Look.values) ButtonSegment(value: look, label: Text(look.name))],
        selected: {look},
        showSelectedIcon: false,
        onSelectionChanged: (selection) => onChanged(selection.single),
      ),
      const SizedBox(height: 10),
      Text(_lookBlurbs[look]!, style: _body),
    ],
  );
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) => const Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('DOTMIND · FLUTTER', style: _eyebrow),
      SizedBox(height: 14),
      Text(
        'The dots know what the model is doing',
        style: TextStyle(
          fontSize: 32,
          height: 1.15,
          fontWeight: FontWeight.w600,
          letterSpacing: -1,
          color: _Palette.ink,
        ),
      ),
      SizedBox(height: 14),
      Text(
        'Plug in the model\'s stream and an 8 × 8 dot matrix follows along: a slow drift while it reasons, '
        'a radar sweep while it searches, a filling page while it writes.',
        style: _body,
      ),
    ],
  );
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.blurb});

  final String title;
  final String blurb;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 22),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600, letterSpacing: -0.2, color: _Palette.ink),
        ),
        const SizedBox(height: 6),
        Text(blurb, style: _body),
      ],
    ),
  );
}

class _CellGrid extends StatelessWidget {
  const _CellGrid({required this.children});

  static const double _minCell = 260;
  static const double _columnGap = 22;
  static const double _rowGap = 18;

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final columns = ((constraints.maxWidth + _columnGap) / (_minCell + _columnGap)).floor().clamp(1, 4);
      final width = (constraints.maxWidth - _columnGap * (columns - 1)) / columns;
      return Wrap(
        spacing: _columnGap,
        runSpacing: _rowGap,
        children: [for (final child in children) SizedBox(width: width, child: child)],
      );
    },
  );
}

class _Cell extends StatelessWidget {
  const _Cell({required this.caption, required this.child});

  final String caption;
  final Widget child;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      child,
      const SizedBox(height: 8),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Text(caption, style: _caption, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
    ],
  );
}

typedef _Beat = (Duration, AgentEvent?);

List<_Beat> _script() {
  const tick = Duration(milliseconds: 90);
  return [
    (const Duration(milliseconds: 700), const AgentEvent.start()),
    for (var i = 0; i < 26; i++) (tick, const AgentEvent.thinking(chars: 24)),
    (const Duration(milliseconds: 200), const AgentEvent.tool('web_search', id: 'search')),
    (const Duration(milliseconds: 2800), const AgentEvent.toolResult(id: 'search')),
    for (var i = 0; i < 10; i++) (tick, const AgentEvent.thinking(chars: 24)),
    (const Duration(milliseconds: 200), const AgentEvent.tool('bash', id: 'code')),
    (const Duration(milliseconds: 2800), const AgentEvent.toolResult(id: 'code')),
    (const Duration(milliseconds: 200), const AgentEvent.tool('deploy_service', id: 'deploy')),
    (const Duration(milliseconds: 2800), const AgentEvent.toolResult(id: 'deploy')),
    for (var i = 0; i < 48; i++) (const Duration(milliseconds: 70), const AgentEvent.text(chars: 18)),
    (const Duration(milliseconds: 200), const AgentEvent.finish()),
    (const Duration(milliseconds: 3200), null),
  ];
}

class LiveTurn extends StatefulWidget {
  const LiveTurn({super.key, this.look = Look.classic});

  final Look look;

  @override
  State<LiveTurn> createState() => _LiveTurnState();
}

class _LiveTurnState extends State<LiveTurn> {
  final ActivityTracker _tracker = ActivityTracker();
  final List<String> _seen = [];
  final List<_Beat> _beats = _script();
  Timer? _timer;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _tracker.addListener(_record);
    _schedule();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _tracker
      ..removeListener(_record)
      ..dispose();
    super.dispose();
  }

  void _schedule() {
    if (_index == _beats.length) {
      _index = 0;
      _tracker.reset();
      setState(_seen.clear);
    }
    final (delay, event) = _beats[_index];
    _timer = Timer(delay, () {
      if (event != null) _tracker.push(event);
      _index++;
      _schedule();
    });
  }

  void _record() {
    final activity = _tracker.value;
    if (activity.phase == Phase.idle) return;
    final label = labelFor(activity);
    if (_seen.isNotEmpty && _seen.last == label) return;
    setState(() => _seen.add(label));
  }

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: _Palette.panel,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: _Palette.rule),
    ),
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('LIVE TURN', style: _eyebrow),
          const SizedBox(height: 18),
          DotMind(
            tracker: _tracker,
            look: widget.look,
            size: 56,
            style: const DotMindStyle(textStyle: TextStyle(fontSize: 24, fontWeight: FontWeight.w500, height: 1.2)),
          ),
          const SizedBox(height: 22),
          const Text('WHAT THE DOTS SHOWED', style: _eyebrow),
          const SizedBox(height: 10),
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 90),
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [for (var i = 0; i < _seen.length; i++) _Chip(_seen[i], on: i == _seen.length - 1)],
            ),
          ),
        ],
      ),
    ),
  );
}

class _Chip extends StatelessWidget {
  const _Chip(this.text, {required this.on});

  final String text;
  final bool on;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: on ? _Palette.chipOn : _Palette.chip,
      borderRadius: const BorderRadius.all(Radius.circular(999)),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      child: Text(
        text.toUpperCase(),
        style: _caption.copyWith(height: 1, letterSpacing: 0.7, color: on ? _Palette.ink : _Palette.inkDim),
      ),
    ),
  );
}
