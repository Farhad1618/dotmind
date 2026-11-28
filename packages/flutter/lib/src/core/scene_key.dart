import 'activity.dart';
import 'phase.dart';
import 'tool_kind.dart';

enum SceneKey {
  idle('idle'),
  thinking('thinking'),
  writing('writing'),
  waiting('waiting'),
  error('error'),
  done('done'),
  toolSearch('tool:search'),
  toolBrowse('tool:browse'),
  toolCode('tool:code'),
  toolFile('tool:file'),
  toolDatabase('tool:database'),
  toolCompute('tool:compute'),
  toolTranslate('tool:translate'),
  toolDeploy('tool:deploy'),
  toolDebug('tool:debug'),
  toolGeneric('tool:generic');

  const SceneKey(this.id);

  final String id;

  static SceneKey of(Activity activity) => switch (activity.phase) {
    Phase.idle => idle,
    Phase.thinking => thinking,
    Phase.tool => forTool(activity.kind ?? ToolKind.generic),
    Phase.writing => writing,
    Phase.waiting => waiting,
    Phase.error => error,
    Phase.done => done,
  };

  static SceneKey forTool(ToolKind kind) => switch (kind) {
    ToolKind.search => toolSearch,
    ToolKind.browse => toolBrowse,
    ToolKind.code => toolCode,
    ToolKind.file => toolFile,
    ToolKind.database => toolDatabase,
    ToolKind.compute => toolCompute,
    ToolKind.translate => toolTranslate,
    ToolKind.deploy => toolDeploy,
    ToolKind.debug => toolDebug,
    ToolKind.generic => toolGeneric,
  };

  static SceneKey? parse(String id) {
    for (final key in values) {
      if (key.id == id) return key;
    }
    return null;
  }
}
