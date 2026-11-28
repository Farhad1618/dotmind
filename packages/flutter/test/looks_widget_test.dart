import 'package:dotmind/dotmind.dart';
import 'package:dotmind/src/widgets/dot_matrix.dart';
import 'package:dotmind/src/widgets/dot_matrix_controller.dart';
import 'package:dotmind/src/widgets/dot_matrix_painter.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

Widget host(Widget child, {bool disableAnimations = false}) => MediaQuery(
  data: MediaQueryData(disableAnimations: disableAnimations),
  child: Directionality(
    textDirection: TextDirection.ltr,
    child: Center(child: child),
  ),
);

DotMatrix matrixOf(WidgetTester tester) => tester.widget<DotMatrix>(find.byType(DotMatrix));

Iterable<BoxDecoration> decorations(WidgetTester tester) => tester
    .widgetList<DecoratedBox>(find.descendant(of: find.byType(DotMind), matching: find.byType(DecoratedBox)))
    .map((box) => box.decoration)
    .whereType<BoxDecoration>();

List<BoxShadow> auraShadows(WidgetTester tester) => [
  for (final decoration in decorations(tester))
    ...?decoration.boxShadow?.where((shadow) => shadow.offset == Offset.zero),
];

Color auraOf(WidgetTester tester) => auraShadows(tester).first.color;

final class RecordingCanvas implements Canvas {
  int circles = 0;
  int roundedRects = 0;
  final List<Color> colors = [];

  @override
  void drawCircle(Offset c, double radius, Paint paint) {
    circles++;
    colors.add(paint.color);
  }

  @override
  void drawRRect(RRect rrect, Paint paint) {
    roundedRects++;
    colors.add(paint.color);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

void main() {
  testWidgets('a look picks the scene and the pixel look draws squares', (tester) async {
    await tester.pumpWidget(
      host(
        const DotMind(
          activity: Activity(Phase.tool, tool: 'set_breakpoint'),
          look: Look.pixel,
        ),
      ),
    );
    final matrix = matrixOf(tester);
    expect(matrix.controller.renderer.scene, Scene.bug);
    expect(matrix.shape, CellShape.square);
    await tester.pumpWidget(host(const DotMind(activity: Activity(Phase.thinking), look: Look.icons)));
    expect(matrixOf(tester).controller.renderer.scene, Scene.neural);
    expect(matrixOf(tester).shape, CellShape.dot);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('the scene option beats overrides, which beat the look', (tester) async {
    await tester.pumpWidget(
      host(
        const DotMind(
          activity: Activity(Phase.thinking),
          look: Look.icons,
          scenes: {SceneKey.thinking: Scene.ember},
          reducedMotion: true,
        ),
      ),
    );
    expect(matrixOf(tester).controller.renderer.scene, Scene.ember);
    await tester.pumpWidget(
      host(
        const DotMind(
          activity: Activity(Phase.thinking),
          look: Look.icons,
          scenes: {SceneKey.thinking: Scene.ember},
          scene: Scene.pulse,
          reducedMotion: true,
        ),
      ),
    );
    expect(matrixOf(tester).controller.renderer.scene, Scene.pulse);
  });

  testWidgets('an explicit shape overrides the look and rounds the well less', (tester) async {
    await tester.pumpWidget(host(const DotMind(look: Look.pixel, shape: CellShape.dot, size: 50)));
    expect(matrixOf(tester).shape, CellShape.dot);
    expect(tester.widget<ClipRRect>(find.byType(ClipRRect)).borderRadius, BorderRadius.circular(50 * 0.24));
    await tester.pumpWidget(host(const DotMind(shape: CellShape.square, size: 50)));
    expect(matrixOf(tester).shape, CellShape.square);
    expect(tester.widget<ClipRRect>(find.byType(ClipRRect)).borderRadius, BorderRadius.circular(50 * 0.14));
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('the aura is on for icons, off for classic, and the option wins', (tester) async {
    await tester.pumpWidget(host(const DotMind(activity: Activity(Phase.thinking), reducedMotion: true)));
    expect(auraShadows(tester), isEmpty);
    await tester.pumpWidget(
      host(const DotMind(activity: Activity(Phase.thinking), look: Look.icons, reducedMotion: true)),
    );
    final shadows = auraShadows(tester);
    expect(shadows, hasLength(2));
    expect(shadows.map((s) => (s.blurRadius, s.spreadRadius)), [(24.0, -6.0), (72.0, 8.0)]);
    expect(shadows[0].color, const Color.fromARGB(255, 150, 104, 255).withValues(alpha: 0.55));
    expect(shadows[1].color, const Color.fromARGB(255, 150, 104, 255).withValues(alpha: 0.2));
    await tester.pumpWidget(
      host(const DotMind(activity: Activity(Phase.thinking), look: Look.icons, aura: false, reducedMotion: true)),
    );
    expect(auraShadows(tester), isEmpty);
    await tester.pumpWidget(host(const DotMind(activity: Activity(Phase.thinking), aura: true, reducedMotion: true)));
    expect(auraShadows(tester), hasLength(2));
    expect(tester.binding.hasScheduledFrame, isFalse);
  });

  testWidgets('a bare indicator glows around the well', (tester) async {
    await tester.pumpWidget(
      host(const DotMind(variant: DotMindVariant.bare, aura: true, size: 40, reducedMotion: true)),
    );
    final well = decorations(tester).single;
    expect(well.borderRadius, BorderRadius.circular(40 * 0.24));
    expect(well.boxShadow!.single.blurRadius, 18);
    expect(well.boxShadow!.single.spreadRadius, 2);
  });

  testWidgets('the aura colour cross-fades with the scene', (tester) async {
    const from = Color.fromARGB(255, 150, 104, 255);
    const to = Color.fromARGB(255, 64, 214, 140);
    await tester.pumpWidget(host(const DotMind(activity: Activity(Phase.thinking), look: Look.icons)));
    expect(auraOf(tester), from.withValues(alpha: 0.55));
    await tester.pumpWidget(host(const DotMind(activity: Activity(Phase.done), look: Look.icons)));
    await tester.pump(const Duration(milliseconds: 150));
    final mid = auraOf(tester);
    expect(mid, isNot(from.withValues(alpha: 0.55)));
    expect(mid, isNot(to.withValues(alpha: 0.55)));
    await tester.pump(const Duration(milliseconds: 250));
    expect(auraOf(tester), to.withValues(alpha: 0.55));
    await tester.pumpWidget(const SizedBox());
  });

  test('the painter draws dots as circles and squares as rounded rectangles', () {
    for (final shape in CellShape.values) {
      final controller = DotMatrixController(Scene.verified);
      controller.renderer.step(1);
      final canvas = RecordingCanvas();
      DotMatrixPainter(controller, shape: shape).paint(canvas, const Size.square(56));
      final drawn = canvas.circles + canvas.roundedRects;
      expect(drawn, greaterThan(cellCount), reason: '${shape.name} draws lit cells');
      expect(canvas.colors.first.a, closeTo(shape.base, 0.5 / 255), reason: shape.name);
      if (shape == CellShape.dot) {
        expect(canvas.roundedRects, 0);
      } else {
        expect(canvas.circles, 0);
      }
      controller.dispose();
    }
  });
}
