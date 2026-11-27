import 'dart:typed_data';

import 'package:dotmind/dotmind.dart';
import 'package:dotmind/src/widgets/dot_matrix.dart';
import 'package:dotmind/src/widgets/dot_matrix_controller.dart';
import 'package:dotmind/src/widgets/shimmer_label.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

Finder label(String text) => find.byWidgetPredicate((widget) => widget is ShimmerLabel && widget.text == text);

DotMatrixController matrixOf(WidgetTester tester) => tester.widget<DotMatrix>(find.byType(DotMatrix)).controller;

List<double> frameOf(DotMatrixController matrix) => matrix.renderer.sample().toList();

Widget host(Widget child, {bool disableAnimations = false}) => MediaQuery(
  data: MediaQueryData(disableAnimations: disableAnimations),
  child: Directionality(
    textDirection: TextDirection.ltr,
    child: Center(child: child),
  ),
);

void main() {
  testWidgets('the label is a polite live region and the canvas is hidden', (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(host(const DotMind(activity: Activity(Phase.thinking))));
    final node = tester.getSemantics(find.byType(DotMind));
    expect(node.label, 'Thinking');
    expect(node.flagsCollection.isLiveRegion, isTrue);
    expect(find.bySemanticsLabel('Thinking'), findsOneWidget);
    expect(node.childrenCount, 0);
    semantics.dispose();
  });

  testWidgets('a hidden label still announces the state', (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(host(const DotMind(activity: Activity(Phase.done), showLabel: false)));
    expect(label('Done'), findsNothing);
    expect(tester.getSemantics(find.byType(DotMind)).label, 'Done');
    semantics.dispose();
  });

  testWidgets('follows a tracker through a turn', (tester) async {
    final tracker = ActivityTracker();
    await tester.pumpWidget(host(DotMind(tracker: tracker)));
    expect(label('Ready'), findsOneWidget);
    tracker.push(const AgentEvent.tool('web_search', id: '1'));
    await tester.pump();
    expect(label('Searching'), findsOneWidget);
    tracker.push(const AgentEvent.text(chars: 5));
    await tester.pump();
    expect(label('Writing'), findsOneWidget);
    tracker.push(const AgentEvent.finish());
    await tester.pump();
    expect(label('Done'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    tracker.dispose();
  });

  testWidgets('classifies a bare tool name and honours custom labels', (tester) async {
    await tester.pumpWidget(
      host(
        DotMind(
          activity: const Activity(Phase.tool, tool: 'run_sql'),
          labels: {toolLabelKey(ToolKind.database): 'Consultando'},
        ),
      ),
    );
    expect(label('Consultando'), findsOneWidget);
  });

  testWidgets('animates while visible', (tester) async {
    await tester.pumpWidget(host(const DotMind(activity: Activity(Phase.thinking))));
    await tester.pump(const Duration(milliseconds: 16));
    expect(tester.binding.hasScheduledFrame, isTrue);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('reduced motion shows a still frame and schedules nothing', (tester) async {
    await tester.pumpWidget(
      host(const DotMind(activity: Activity(Phase.writing, progress: 40)), disableAnimations: true),
    );
    await tester.pump();
    expect(tester.binding.hasScheduledFrame, isFalse);
    await tester.pumpWidget(host(const DotMind(activity: Activity(Phase.done)), disableAnimations: true));
    await tester.pump();
    expect(label('Done'), findsOneWidget);
    expect(tester.binding.hasScheduledFrame, isFalse);
  });

  testWidgets('the reduced-motion still frame survives parent rebuilds', (tester) async {
    await tester.pumpWidget(host(const DotMind(activity: Activity(Phase.thinking)), disableAnimations: true));
    final matrix = matrixOf(tester);
    final first = frameOf(matrix);
    for (var i = 0; i < 3; i++) {
      await tester.pumpWidget(host(const DotMind(activity: Activity(Phase.thinking)), disableAnimations: true));
    }
    expect(frameOf(matrix), first);
    expect(matrix.renderer.clock, closeTo(1.7, 1e-9));
  });

  testWidgets('turning on reduced motion settles once', (tester) async {
    await tester.pumpWidget(host(const DotMind(activity: Activity(Phase.thinking), reducedMotion: false)));
    final matrix = matrixOf(tester);
    final before = matrix.renderer.clock;
    await tester.pumpWidget(host(const DotMind(activity: Activity(Phase.thinking), reducedMotion: true)));
    expect(matrix.renderer.clock, closeTo(before + 1.7, 1e-9));
    await tester.pump();
    expect(matrix.renderer.clock, closeTo(before + 1.7, 1e-9));
    expect(tester.binding.hasScheduledFrame, isFalse);
  });

  testWidgets('a matrix scrolled out of view stops drawing', (tester) async {
    final scroll = ScrollController();
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(size: Size(400, 600)),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: SingleChildScrollView(
            controller: scroll,
            child: const Column(
              children: [
                SizedBox(height: 2000),
                DotMind(activity: Activity(Phase.thinking)),
                SizedBox(height: 2000),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(tester.binding.hasScheduledFrame, isFalse);
    expect(matrixOf(tester).isLive, isFalse);
    scroll.jumpTo(1800);
    await tester.pump();
    expect(matrixOf(tester).isLive, isTrue);
    expect(tester.binding.hasScheduledFrame, isTrue);
    scroll.jumpTo(3000);
    await tester.pump();
    await tester.pump();
    expect(matrixOf(tester).isLive, isFalse);
    expect(tester.binding.hasScheduledFrame, isFalse);
    await tester.pumpWidget(const SizedBox());
    scroll.dispose();
  });

  testWidgets('the phase shorthand takes labels, palette, scene and reduced motion', (tester) async {
    await tester.pumpWidget(
      host(
        DotMind.phase(
          Phase.thinking,
          labels: const {'thinking': 'Pensando'},
          palette: const {Scene.ember: Rgb(10, 20, 30)},
          scene: Scene.ember,
          reducedMotion: true,
        ),
      ),
    );
    expect(label('Pensando'), findsOneWidget);
    expect(matrixOf(tester).renderer.scene, Scene.ember);
    final rgb = Float64List(3);
    matrixOf(tester).renderer.writeColor(rgb);
    expect(rgb.toList(), [10, 20, 30]);
    expect(tester.binding.hasScheduledFrame, isFalse);
  });

  testWidgets('the shimmer repaints from the matrix ticker', (tester) async {
    await tester.pumpWidget(host(const DotMind(activity: Activity(Phase.thinking))));
    final matrix = matrixOf(tester);
    await tester.pump(const Duration(milliseconds: 16));
    await tester.pump(const Duration(milliseconds: 16));
    expect(matrix.elapsed, greaterThan(0));
    expect(tester.widget<ShimmerLabel>(find.byType(ShimmerLabel)).driver, same(matrix));
    expect(find.byType(AnimatedBuilder), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('a disabled TickerMode pauses drawing', (tester) async {
    await tester.pumpWidget(host(const TickerMode(enabled: false, child: DotMind(activity: Activity(Phase.thinking)))));
    await tester.pump();
    expect(tester.binding.hasScheduledFrame, isFalse);
  });

  testWidgets('a backgrounded app pauses drawing', (tester) async {
    await tester.pumpWidget(host(const DotMind(activity: Activity(Phase.thinking))));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    expect(tester.binding.hasScheduledFrame, isFalse);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(tester.binding.hasScheduledFrame, isTrue);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('renders every scene in both variants', (tester) async {
    for (final scene in Scene.values) {
      for (final variant in DotMindVariant.values) {
        await tester.pumpWidget(host(DotMind(scene: scene, variant: variant, label: scene.name)));
        await tester.pump(const Duration(milliseconds: 100));
        expect(label(scene.name), findsOneWidget);
      }
    }
    await tester.pumpWidget(const SizedBox());
  });
}
