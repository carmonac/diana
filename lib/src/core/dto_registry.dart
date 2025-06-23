class DtoRegistry {
  static final Map<Type, Function> _fieldExtractors = {};
  static final Map<Type, Function> _deserializers = {};

  static void registerDto<T>({
    required Map<String, dynamic> Function(T object) fieldExtractor,
    required T Function(Map<String, dynamic>) fromJson,
  }) {
    _fieldExtractors[T] = fieldExtractor;
    _deserializers[T] = fromJson;
  }

  static Map<String, dynamic>? serialize(dynamic object) {
    final extractor = _fieldExtractors[object.runtimeType];
    if (extractor != null) {
      return extractor(object) as Map<String, dynamic>;
    }
    return null;
  }

  static T? deserialize<T>(Map<String, dynamic> json) {
    final deserializer = _deserializers[T];
    if (deserializer != null) {
      return deserializer(json) as T;
    }
    return null;
  }

  static dynamic deserializeByType(Map<String, dynamic> json, Type type) {
    final deserializer = _deserializers[type];
    return deserializer?.call(json);
  }

  static bool isRegistered(Type type) {
    return _fieldExtractors.containsKey(type);
  }
}
