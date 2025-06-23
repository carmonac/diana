import 'dart:convert';

import 'package:shelf/shelf.dart';
import '../core/dto_registry.dart';
import 'response.dart';

class ResponseProcessor {
  static DianaResponse processResponse(dynamic result) {
    if (result is DianaResponse) {
      return result;
    } else if (result is Response) {
      return DianaResponse.fromShelf(result);
    } else if (result is String) {
      return DianaResponse.text(result);
    } else if (result == null) {
      return DianaResponse.ok(null);
    } else {
      // Intentar serializar como JSON, si falla usar toString()
      try {
        final jsonData = _convertToJson(result);
        return DianaResponse.json(jsonData);
      } catch (e) {
        print('Failed to serialize response to JSON: $e');
        return DianaResponse.text(result.toString());
      }
    }
  }

  static dynamic _convertToJson(dynamic object) {
    if (object == null || object is String || object is num || object is bool) {
      return object;
    }

    if (object is List) {
      return object.map(_convertToJson).toList();
    }

    if (object is Map) {
      return object.map(
        (key, value) => MapEntry(key.toString(), _convertToJson(value)),
      );
    }

    if (DtoRegistry.isRegistered(object.runtimeType)) {
      final serializedData = DtoRegistry.serialize(object);
      if (serializedData != null) {
        return serializedData;
      }
    }

    try {
      final toJsonMethod = (object as dynamic).toJson;
      if (toJsonMethod != null) {
        return toJsonMethod();
      }
    } catch (e) {
      // El objeto no tiene toJson(), continuar
    }

    return json.decode(json.encode(object));
  }
}
