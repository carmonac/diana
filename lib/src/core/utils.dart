import 'dto_registry.dart';

String generateRequestId() {
  final now = DateTime.now();
  final timestamp = now.millisecondsSinceEpoch.toString();
  final randomPart = (100000 + (now.microsecondsSinceEpoch % 900000))
      .toString();
  return '$timestamp-$randomPart';
}

dynamic deserializeToType(Map<String, dynamic> map, Type type) {
  if (type == String) {
    return map.toString();
  } else if (type == int) {
    return map['value'] as int?;
  } else if (type == double) {
    return map['value'] as double?;
  } else if (type == bool) {
    return map['value'] as bool?;
  }

  if (DtoRegistry.isRegistered(type)) {
    return DtoRegistry.deserializeByType(map, type);
  }

  // Fallback
  return map;
}
