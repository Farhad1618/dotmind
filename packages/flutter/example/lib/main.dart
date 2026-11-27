import 'dart:async';

import 'package:dotmind/adapters.dart';
import 'package:dotmind/dotmind.dart';
import 'package:material_ui/material_ui.dart';

void main() => runApp(const DotMindGallery());

const List<(String, Activity)> _states = [
  ('Idle', Activity(Phase.idle)),
  ('Thinking', Activity(Phase.thinking)),
  ('Search tool', Activity(Phase.tool, tool: 'web_search', kind: ToolKind.search)),
  ('Browse tool', Activity(Phase.tool, tool: 'web_fetch', kind: ToolKind.browse)),
  ('Code tool', Activity(Phase.tool, tool: 'bash', kind: ToolKind.code)),
  ('File tool', Activity(Phase.tool, tool: 'read_file', kind: ToolKind.file)),
  ('Database tool', Activity(Phase.tool, tool: 'run_sql', kind: ToolKind.database)),
  ('Compute tool', Activity(Phase.tool, tool: 'calculate_margin', kind: ToolKind.compute)),
  ('Other tool', Activity(Phase.tool, tool: 'get_weather', kind: ToolKind.generic)),
  ('Writing', Activity(Phase.writing, progress: 96)),
  ('Waiting', Activity(Phase.waiting, tool: 'deploy_config')),
  ('Error', Activity(Phase.error)),
  ('Done', Activity(Phase.done)),
];

class DotMindGallery extends StatelessWidget {
  const DotMindGallery({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'dotmind',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(brightness: Brightness.dark, scaffoldBackgroundColor: const Color(0xFF111113)),
    home: const GalleryPage(),
  );
}

class GalleryPage extends StatelessWidget {
  const GalleryPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const _Heading('A model turn'),
          const SimulatedTurn(),
          const SizedBox(height: 32),
          const _Heading('Every state'),
          for (final (name, activity) in _states)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  SizedBox(
                    width: 128,
                    child: Text(name, style: const TextStyle(color: Colors.white54)),
                  ),
                  Flexible(child: DotMind(activity: activity)),
                ],
              ),
            ),
          const SizedBox(height: 32),
          const _Heading('Bare, inline'),
          const Row(
            children: [
              DotMind(activity: Activity(Phase.writing), variant: DotMindVariant.bare, size: 18),
              SizedBox(width: 24),
              DotMind(activity: Activity(Phase.thinking), variant: DotMindVariant.bare, size: 18, showLabel: false),
            ],
          ),
          const SizedBox(height: 32),
          const _Heading('Extra scenes'),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              for (final scene in const [Scene.ember, Scene.orbit, Scene.serpent, Scene.pulse])
                DotMind(scene: scene, label: scene.name),
            ],
          ),
        ],
      ),
    ),
  );
}

class _Heading extends StatelessWidget {
  const _Heading(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Text(
      text,
      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
    ),
  );
}

List<JsonMap> _turn() => [
  {'type': 'message_start'},
  {
    'type': 'content_block_start',
    'content_block': {'type': 'thinking'},
  },
  for (var i = 0; i < 20; i++)
    {
      'type': 'content_block_delta',
      'delta': {'type': 'thinking_delta', 'thinking': 'considering...'},
    },
  {
    'type': 'content_block_start',
    'content_block': {'type': 'server_tool_use', 'name': 'web_search', 'id': 's1'},
  },
  {
    'type': 'content_block_start',
    'content_block': {'type': 'web_search_tool_result', 'tool_use_id': 's1'},
  },
  {
    'type': 'content_block_start',
    'content_block': {'type': 'mcp_tool_use', 'name': 'run_sql', 'id': 'q1'},
  },
  {
    'type': 'content_block_start',
    'content_block': {'type': 'mcp_tool_result', 'tool_use_id': 'q1'},
  },
  {
    'type': 'content_block_start',
    'content_block': {'type': 'text'},
  },
  for (var i = 0; i < 80; i++)
    {
      'type': 'content_block_delta',
      'delta': {'type': 'text_delta', 'text': 'churn '},
    },
  {
    'type': 'message_delta',
    'delta': {'stop_reason': 'end_turn'},
  },
  {'type': 'message_stop'},
];

Duration _delayFor(JsonMap event) {
  final block = event['content_block'];
  if (block is Map && '${block['type']}'.endsWith('tool_result')) return const Duration(milliseconds: 2400);
  if (event['type'] == 'content_block_delta') return const Duration(milliseconds: 60);
  return const Duration(milliseconds: 300);
}

Stream<JsonMap> _replay(List<JsonMap> events) async* {
  for (final event in events) {
    await Future<void>.delayed(_delayFor(event));
    yield event;
  }
}

class SimulatedTurn extends StatefulWidget {
  const SimulatedTurn({super.key});

  @override
  State<SimulatedTurn> createState() => _SimulatedTurnState();
}

class _SimulatedTurnState extends State<SimulatedTurn> {
  final ActivityTracker _tracker = ActivityTracker();
  bool _running = false;

  @override
  void dispose() {
    _tracker.dispose();
    super.dispose();
  }

  Future<void> _run() async {
    if (_running) return;
    setState(() => _running = true);
    _tracker.reset();
    try {
      await followAnthropicStream(_replay(_turn()), _tracker);
    } finally {
      if (mounted) setState(() => _running = false);
    }
  }

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Flexible(child: DotMind(tracker: _tracker)),
      const SizedBox(width: 16),
      FilledButton(onPressed: _running ? null : _run, child: Text(_running ? 'Streaming' : 'Run a turn')),
    ],
  );
}
