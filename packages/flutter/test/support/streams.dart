import 'package:dotmind/dotmind.dart';

Stream<T> streamOf<T>(List<T> items) => Stream<T>.fromIterable(items);

String keyOf(Activity a) =>
    a.phase == Phase.tool || a.phase == Phase.waiting ? '${a.phase.name}:${a.tool}' : a.phase.name;

List<String> record(ActivityTracker tracker) {
  final seen = <String>[];
  tracker.subscribe((a) {
    final key = keyOf(a);
    if (seen.isEmpty || seen.last != key) seen.add(key);
  });
  return seen;
}
