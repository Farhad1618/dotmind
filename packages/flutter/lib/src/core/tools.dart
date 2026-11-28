import 'tool_kind.dart';

const List<(ToolKind, List<String>)> _rules = [
  (ToolKind.search, ['search', 'find', 'lookup', 'grep', 'retriev', 'rag', 'google', 'bing', 'glob']),
  (
    ToolKind.database,
    ['sql', 'db', 'database', 'table', 'query', 'clickhouse', 'postgres', 'bigquery', 'snowflake', 'mongo', 'redis'],
  ),
  (
    ToolKind.browse,
    [
      'browse',
      'browser',
      'navigate',
      'fetch',
      'url',
      'scrape',
      'crawl',
      'http',
      'page',
      'click',
      'screenshot',
      'computer',
      'web',
    ],
  ),
  (
    ToolKind.code,
    [
      'code',
      'exec',
      'run',
      'python',
      'bash',
      'shell',
      'terminal',
      'sandbox',
      'eval',
      'interpreter',
      'script',
      'notebook',
    ],
  ),
  (
    ToolKind.file,
    [
      'file',
      'read',
      'write',
      'edit',
      'fs',
      'doc',
      'pdf',
      'upload',
      'download',
      'save',
      'replace',
      'editor',
      'ls',
      'dir',
    ],
  ),
  (ToolKind.compute, ['calc', 'math', 'compute', 'sum', 'stat', 'analy', 'chart', 'plot', 'forecast']),
  (
    ToolKind.translate,
    [
      'translate',
      'translation',
      'translator',
      'i18n',
      'localize',
      'localise',
      'localization',
      'localisation',
      'l10n',
      'locale',
    ],
  ),
  (ToolKind.deploy, ['deploy', 'deployment', 'release', 'publish', 'rollout', 'ship', 'kubectl', 'helm']),
  (ToolKind.debug, ['debug', 'debugger', 'breakpoint', 'stacktrace', 'traceback', 'inspect']),
];

final RegExp _camelBoundary = RegExp('([a-z0-9])([A-Z])');
final RegExp _separators = RegExp('[^a-z0-9]+');

List<String> toolTokens(String name) => name
    .replaceAllMapped(_camelBoundary, (m) => '${m[1]}_${m[2]}')
    .toLowerCase()
    .split(_separators)
    .where((token) => token.isNotEmpty)
    .toList();

bool _matches(String token, String word) => token == word || (word.length > 3 && token.startsWith(word));

ToolKind classifyTool(String? name, [Map<String, ToolKind>? overrides]) {
  if (name == null || name.isEmpty) return ToolKind.generic;
  final own = overrides?[name];
  if (own != null) return own;
  final tokens = toolTokens(name);
  for (final (kind, words) in _rules) {
    if (tokens.any((token) => words.any((word) => _matches(token, word)))) {
      return kind;
    }
  }
  return ToolKind.generic;
}

String humanizeTool(String name) => toolTokens(name).join(' ');
