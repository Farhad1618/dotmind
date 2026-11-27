import 'package:dotmind/dotmind.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('the tracker follows a tool-using turn', () {
    final t = ActivityTracker();
    final phases = <String>[];
    t.subscribe((a) => phases.add(a.phase == Phase.tool ? 'tool:${a.kind!.name}' : a.phase.name));
    t.pushAll(const [
      AgentEvent.start(),
      AgentEvent.thinking(chars: 120),
      AgentEvent.tool('web_search', id: 'a'),
      AgentEvent.toolResult(id: 'a'),
      AgentEvent.text(chars: 40),
      AgentEvent.text(chars: 40),
      AgentEvent.finish(),
    ]);
    expect(phases.toSet().toList(), ['idle', 'thinking', 'tool:search', 'writing', 'done']);
    expect(t.activity.progress, 200);
  });

  test('a turn that stops to run a client tool stays on that tool', () {
    final t = ActivityTracker();
    t.pushAll(const [AgentEvent.start(), AgentEvent.tool('run_sql', id: 'x'), AgentEvent.finish(pendingTools: true)]);
    expect(t.activity.phase, Phase.tool);
    expect(t.activity.kind, ToolKind.database);
  });

  test('a pending finish shows the most recently opened tool still open', () {
    final t = ActivityTracker();
    t.pushAll(const [
      AgentEvent.start(),
      AgentEvent.tool('read_file', id: 'a'),
      AgentEvent.tool('bash', id: 'b'),
      AgentEvent.toolResult(id: 'b'),
      AgentEvent.finish(pendingTools: true),
    ]);
    expect(t.activity.tool, 'read_file');
    expect(t.activity.kind, ToolKind.file);
  });

  test('tool overrides apply to classification', () {
    final t = ActivityTracker(tools: {'lookup_customer': ToolKind.database});
    t.push(const AgentEvent.tool('lookup_customer', id: '1'));
    expect(t.activity.kind, ToolKind.database);
  });

  test('tool input grows progress without changing the tool', () {
    final t = ActivityTracker();
    t.pushAll(const [AgentEvent.tool('bash', id: '1'), AgentEvent.toolInput(chars: 12)]);
    expect(t.activity.phase, Phase.tool);
    expect(t.activity.tool, 'bash');
    expect(t.activity.progress, 12);
  });

  test('approval waits on the named tool and errors show the error phase', () {
    final t = ActivityTracker();
    t.push(const AgentEvent.approval(name: 'deploy_config', id: 'ap'));
    expect(t.activity.phase, Phase.waiting);
    expect(t.activity.tool, 'deploy_config');
    t.push(const AgentEvent.error(message: 'boom'));
    expect(t.activity.phase, Phase.error);
  });

  test('listeners fire only on real changes and stop after unsubscribing', () {
    final t = ActivityTracker();
    var calls = 0;
    final stop = t.subscribe((_) => calls++);
    expect(calls, 1);
    t.push(const AgentEvent.start());
    t.push(const AgentEvent.thinking());
    expect(calls, 2);
    var notified = 0;
    t.addListener(() => notified++);
    t.push(const AgentEvent.thinking(chars: 3));
    expect(calls, 3);
    expect(notified, 1);
    expect(t.value, t.activity);
    stop();
    t.reset();
    expect(calls, 3);
    expect(t.activity, const Activity(Phase.idle, progress: 0));
  });
}
