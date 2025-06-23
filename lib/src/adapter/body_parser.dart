import 'dart:convert';
import 'package:shelf/shelf.dart';
import '../core/dto_registry.dart';
import '../core/handler_composer.dart';
import '../core/exceptions/exceptions.dart';

class BodyParser {
  static Future<dynamic> parseBodyParameter(
    Request request,
    Parameter param,
  ) async {
    final contentType = request.headers['content-type'];

    if (contentType == null) {
      return null;
    }

    if (contentType.toLowerCase().contains('application/json')) {
      return await _parseJsonBody(request, param);
    }

    return await request.readAsString();
  }

  static Future<dynamic> _parseJsonBody(
    Request request,
    Parameter param,
  ) async {
    try {
      final bodyString = await request.readAsString();

      if (bodyString.isEmpty) {
        return null;
      }

      if (param.typeOf != null) {
        final jsonMap = json.decode(bodyString) as Map<String, dynamic>;
        return _deserializeToType(jsonMap, param.typeOf!);
      }

      return json.decode(bodyString);
    } catch (e) {
      throw BadRequestException('Invalid JSON body: $e');
    }
  }

  static dynamic _deserializeToType(Map<String, dynamic> jsonMap, Type type) {
    if (type == String) {
      return jsonMap.toString();
    } else if (type == int) {
      return jsonMap['value'] as int?;
    } else if (type == double) {
      return jsonMap['value'] as double?;
    } else if (type == bool) {
      return jsonMap['value'] as bool?;
    }

    if (DtoRegistry.isRegistered(type)) {
      return DtoRegistry.deserializeByType(jsonMap, type);
    }

    // Fallback
    return jsonMap;
  }
}
