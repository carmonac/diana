import 'dart:async';
import 'dart:convert';

import 'package:diana/diana.dart';

@ContentTypeSerializer(['application/json', 'text/json'])
class JsonContentType extends ContentType with Serializable, Deserializable {
  JsonContentType(super.contentTypes);

  @override
  Future<dynamic> deserialize(DianaRequest request, Type type) async {
    try {
      final bodyString = await request.readAsString();

      if (bodyString.isEmpty) {
        return null;
      }

      final jsonData = json.decode(bodyString);

      if (jsonData is List) {
        if (type.toString().startsWith('List<')) {
          final elementTypeName = type
              .toString()
              .replaceFirst('List<', '')
              .replaceFirst('>', '');
          return jsonData.map((item) {
            if (item is Map<String, dynamic>) {
              final elementType = _findTypeByName(elementTypeName);
              if (elementType != null) {
                return _deserializeByType(item, elementType);
              }
              return item;
            }
            return item;
          }).toList();
        }
        return jsonData;
      }

      if (jsonData is Map<String, dynamic>) {
        return _deserializeByType(jsonData, type);
      }
      return jsonData;
    } catch (e) {
      throw BadRequestException('Invalid JSON body: $e');
    }
  }

  dynamic _deserializeByType(Map<String, dynamic> jsonData, Type type) {
    if (DtoRegistry.isRegistered(type)) {
      return DtoRegistry.deserializeByType(jsonData, type);
    } else if (type == String) {
      return jsonData.toString();
    } else if (type == int) {
      return jsonData['value'];
    } else if (type == double) {
      return jsonData['value'];
    } else if (type == bool) {
      return jsonData['value'];
    }
    // Fallback for unsupported types
    return jsonData;
  }

  @override
  dynamic serialize(dynamic object) {
    if (object == null) {
      return 'null';
    }
    if (object is String || object is num || object is bool) {
      return json.encode(object);
    }
    if (object is List) {
      // Serializar cada elemento de la lista
      final serializedList = object.map((item) {
        if (item != null && DtoRegistry.isRegistered(item.runtimeType)) {
          // Si el elemento está registrado en DtoRegistry, serializarlo
          return DtoRegistry.serialize(item);
        } else if (item is Map) {
          // Si es un Map, serializarlo recursivamente
          return item.map(
            (key, value) => MapEntry(key.toString(), _serializeValue(value)),
          );
        } else {
          // Para otros tipos, usar serialización recursiva
          return _serializeItem(item);
        }
      }).toList();

      return json.encode(serializedList);
    }

    if (object is Map) {
      return object.map(
        (key, value) => MapEntry(key.toString(), _serializeValue(value)),
      );
    }

    if (DtoRegistry.isRegistered(object.runtimeType)) {
      final serializedData = DtoRegistry.serialize(object);
      if (serializedData != null) {
        return json.encode(serializedData);
      }
    }

    try {
      if (object.runtimeType.toString().contains('toJson')) {
        final toJsonMethod = (object as dynamic).toJson;
        if (toJsonMethod is Function) {
          final result = toJsonMethod();
          return json.encode(result);
        }
      }
    } on NoSuchMethodError {
      // If the object does not have a toJson() method, continue
    } catch (e) {
      // Log error but continue to fallback
    }

    try {
      return json.encode(object);
    } catch (e) {
      // If object is not JSON-encodable, convert to string representation
      return json.encode(object.toString());
    }
  }

  dynamic _serializeItem(dynamic item) {
    if (item == null || item is String || item is num || item is bool) {
      return item;
    }

    if (DtoRegistry.isRegistered(item.runtimeType)) {
      return DtoRegistry.serialize(item);
    }

    if (item is List) {
      return item.map(_serializeItem).toList();
    }

    if (item is Map) {
      return item.map(
        (key, value) => MapEntry(key.toString(), _serializeItem(value)),
      );
    }

    try {
      if (item.runtimeType.toString().contains('toJson')) {
        final toJsonMethod = (item as dynamic).toJson;
        if (toJsonMethod is Function) {
          return toJsonMethod();
        }
      }
    } on NoSuchMethodError {
      // Continue to fallback
    } catch (e) {
      // Continue to fallback
    }

    // Fallback: return the item as-is and let json.encode handle it
    return item;
  }

  dynamic _serializeValue(dynamic value) {
    if (value == null || value is String || value is num || value is bool) {
      return value;
    }
    return json.decode(serialize(value));
  }

  Type? _findTypeByName(String typeName) {
    switch (typeName) {
      case 'String':
        return String;
      case 'int':
        return int;
      case 'double':
        return double;
      case 'bool':
        return bool;
      case 'num':
        return num;
      case 'Object':
        return Object;
      case 'dynamic':
        return dynamic;
    }
    return DtoRegistry.findTypeByName(typeName);
  }
}
