import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../core/activity.dart';
import '../core/labels.dart';
import '../core/patterns/catalog.dart';
import '../core/phase.dart';
import '../core/rgb.dart';
import '../core/scene.dart';
import '../core/scene_selection.dart';
import '../core/tools.dart';
import 'dot_matrix.dart';
import 'dot_matrix_controller.dart';
import 'dot_mind_style.dart';
import 'dot_mind_variant.dart';
import 'shimmer_label.dart';

const Set<Phase> _settledPhases = {Phase.idle, Phase.done, Phase.error};

typedef _Presentation = ({Phase phase, Scene scene, Rgb color, String text, String announcement});

Activity _normalize(Activity activity) {
  final tool = activity.tool;
  if (activity.kind != null || tool == null || tool.isEmpty) return activity;
  return Activity(
    activity.phase,
    tool: tool,
    kind: classifyTool(tool),
    label: activity.label,
    progress: activity.progress,
  );
}

Color _glowFor(Rgb color) => Color.fromARGB(255, (color.r + 510) ~/ 3, (color.g + 510) ~/ 3, (color.b + 510) ~/ 3);

class DotMind extends StatefulWidget {
  const DotMind({
    super.key,
    this.activity = Activity.idle,
    this.tracker,
    this.variant = DotMindVariant.pill,
    this.size = 28,
    this.label,
    this.showLabel = true,
    this.labels = const {},
    this.palette = const {},
    this.scene,
    this.reducedMotion,
    this.style = const DotMindStyle(),
  });

  DotMind.phase(
    Phase phase, {
    Key? key,
    DotMindVariant variant = DotMindVariant.pill,
    double size = 28,
    String? label,
    bool showLabel = true,
    Map<String, String> labels = const {},
    Map<Scene, Rgb> palette = const {},
    Scene? scene,
    bool? reducedMotion,
    DotMindStyle style = const DotMindStyle(),
  }) : this(
         key: key,
         activity: Activity(phase),
         variant: variant,
         size: size,
         label: label,
         showLabel: showLabel,
         labels: labels,
         palette: palette,
         scene: scene,
         reducedMotion: reducedMotion,
         style: style,
       );

  final Activity activity;
  final ValueListenable<Activity>? tracker;
  final DotMindVariant variant;
  final double size;
  final String? label;
  final bool showLabel;
  final Map<String, String> labels;
  final Map<Scene, Rgb> palette;
  final Scene? scene;
  final bool? reducedMotion;
  final DotMindStyle style;

  @override
  State<DotMind> createState() => _DotMindState();
}

class _DotMindState extends State<DotMind> {
  final DotMatrixController _matrix = DotMatrixController();
  ValueListenable<Activity>? _listening;
  _Presentation? _presentation;
  bool _still = false;

  Activity get _activity => _normalize(widget.tracker?.value ?? widget.activity);

  @override
  void initState() {
    super.initState();
    _listen(widget.tracker);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _still = widget.reducedMotion ?? MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    _apply();
  }

  @override
  void didUpdateWidget(DotMind oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.tracker != widget.tracker) _listen(widget.tracker);
    _still = widget.reducedMotion ?? MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    _apply();
  }

  @override
  void dispose() {
    _listening?.removeListener(_onTracker);
    _matrix.dispose();
    super.dispose();
  }

  void _listen(ValueListenable<Activity>? source) {
    _listening?.removeListener(_onTracker);
    _listening = source;
    source?.addListener(_onTracker);
  }

  void _onTracker() {
    final before = _presentation;
    if (_apply() != before) setState(() {});
  }

  _Presentation _apply() {
    final activity = _activity;
    final scene = widget.scene ?? sceneFor(activity);
    final color = widget.palette[scene] ?? sceneColor(scene);
    _matrix.still = _still;
    _matrix.present(scene, color, activity.progress);
    final announcement = widget.label ?? labelFor(activity, widget.labels);
    final presentation = (
      phase: activity.phase,
      scene: scene,
      color: color,
      text: widget.showLabel ? announcement : '',
      announcement: announcement.isEmpty ? labelFor(activity, widget.labels) : announcement,
    );
    _presentation = presentation;
    return presentation;
  }

  ShimmerMode _shimmerMode(Phase phase) {
    if (_settledPhases.contains(phase)) return ShimmerMode.off;
    return _still ? ShimmerMode.still : ShimmerMode.moving;
  }

  @override
  Widget build(BuildContext context) {
    final p = _presentation ?? _apply();
    final style = widget.style;
    final em = style.fontSize;
    final hasLabel = p.text.isNotEmpty;
    final row = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        DotMatrix(controller: _matrix, size: widget.size, well: style.well, still: _still),
        if (hasLabel) SizedBox(width: em * 0.6),
        if (hasLabel)
          Flexible(
            child: ShimmerLabel(
              text: p.text,
              style: style.textStyle,
              ink: style.ink,
              peak: style.peak,
              glow: _glowFor(p.color),
              period: style.shimmerPeriod,
              driver: _matrix,
              mode: _shimmerMode(p.phase),
            ),
          ),
      ],
    );
    final body = widget.variant == DotMindVariant.bare ? row : _pill(row, hasLabel, em);
    return Semantics(
      container: true,
      liveRegion: true,
      label: p.announcement,
      child: ExcludeSemantics(child: body),
    );
  }

  Widget _pill(Widget child, bool hasLabel, double em) {
    final style = widget.style;
    final inset = em * 0.35;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: style.background,
        borderRadius: const BorderRadius.all(Radius.circular(999)),
        border: Border.all(color: style.edge),
        boxShadow: style.elevated
            ? const [BoxShadow(color: Color(0xCC000000), offset: Offset(0, 10), blurRadius: 30, spreadRadius: -14)]
            : null,
      ),
      child: Padding(padding: EdgeInsets.fromLTRB(inset, inset, hasLabel ? em * 1.15 : inset, inset), child: child),
    );
  }
}
