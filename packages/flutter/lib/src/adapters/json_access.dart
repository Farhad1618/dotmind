typedef JsonMap = Map<String, Object?>;

Map<Object?, Object?>? jsonMap(Object? value) => value is Map<Object?, Object?> ? value : null;

List<Object?> jsonList(Object? value) => value is List<Object?> ? value : const [];

String? jsonString(Map<Object?, Object?>? map, String key) {
  final value = map?[key];
  return value is String ? value : null;
}

int jsonLength(Map<Object?, Object?>? map, String key) => jsonString(map, key)?.length ?? 0;

bool isFilled(String? value) => value != null && value.isNotEmpty;
