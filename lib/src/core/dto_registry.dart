class DtoRegistry {
  static final Map<Type, Function> _fieldExtractors = {};
  static final Map<Type, Function> _deserializers = {};
  static final Map<Type, Function> _customOptions = {};

  static void registerDto<T>({
    required Map<String, dynamic> Function(T object) fieldExtractor,
    required T Function(Map<String, dynamic>) fromMap,
    Map<String, dynamic> Function(T object)? customOptions,
  }) {
    _fieldExtractors[T] = fieldExtractor;
    _deserializers[T] = fromMap;
    if (customOptions != null) {
      _customOptions[T] = customOptions;
    }
  }

  static Map<String, dynamic>? serialize(dynamic object) {
    final extractor = _fieldExtractors[object.runtimeType];
    if (extractor != null) {
      return extractor(object) as Map<String, dynamic>;
    }
    return null;
  }

  static T? deserialize<T>(Map<String, dynamic> map) {
    final deserializer = _deserializers[T];
    if (deserializer != null) {
      return deserializer(map) as T;
    }
    return null;
  }

  static dynamic deserializeByType(Map<String, dynamic> map, Type type) {
    final deserializer = _deserializers[type];
    return deserializer?.call(map);
  }

  static bool isRegistered(Type type) {
    return _fieldExtractors.containsKey(type);
  }

  static Type? findTypeByName(String typeName) {
    for (final type in _fieldExtractors.keys) {
      if (type.toString() == typeName) {
        return type;
      }
    }
    return null;
  }

  static Map<String, dynamic>? getCustomOptions(dynamic object) {
    final type = object.runtimeType;
    final customOptionsExtractor = _customOptions[type];
    if (customOptionsExtractor != null) {
      return customOptionsExtractor(object) as Map<String, dynamic>;
    }
    return null;
  }
}
