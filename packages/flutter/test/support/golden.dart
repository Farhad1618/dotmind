import 'dart:convert';
import 'dart:io';

import 'package:dotmind/dotmind.dart';

final class Golden {
  Golden._(this.data);

  factory Golden.load() {
    final file = File('../../spec/golden.json');
    final data = jsonDecode(file.readAsStringSync()) as Map<String, Object?>;
    return Golden._(data);
  }

  final Map<String, Object?> data;

  double get tolerance => (data['tolerance']! as num).toDouble();

  List<Map<String, Object?>> section(String name) => (data[name]! as List<Object?>).cast<Map<String, Object?>>();
}

List<double> numbers(Object? values) => (values! as List<Object?>).map((v) => (v! as num).toDouble()).toList();

Scene sceneNamed(Object? name) => Scene.values.byName(name! as String);

Activity activityFrom(Map<String, Object?> json) {
  final kind = json['kind'] as String?;
  return Activity(
    Phase.values.byName(json['phase']! as String),
    tool: json['tool'] as String?,
    kind: kind == null ? null : ToolKind.values.byName(kind),
  );
}
