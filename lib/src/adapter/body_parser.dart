import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:xml/xml.dart';
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

    if (contentType.toLowerCase().contains('application/xml') ||
        contentType.toLowerCase().contains('text/xml')) {
      return await _parseXmlBody(request, param);
    }

    if (contentType.toLowerCase().contains('application/sparql-query') ||
        contentType.toLowerCase().contains('application/sparql-update')) {
      return await _parseSparqlBody(request, param);
    }

    // x-www-form-urlencoded
    if (contentType.toLowerCase().contains(
      'application/x-www-form-urlencoded',
    )) {
      return await _parseFormUrlEncodedBody(request, param);
    }

    // multipart/form-data
    if (contentType.toLowerCase().contains('multipart/form-data')) {
      return await _parseMultipartFormDataBody(request, param);
    }

    if (contentType.toLowerCase().contains('text/plain')) {
      return await request.readAsString();
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

  static Future<dynamic> _parseXmlBody(Request request, Parameter param) async {
    try {
      final bodyString = await request.readAsString();

      if (bodyString.isEmpty) {
        return null;
      }

      // Parse the XML
      final document = XmlDocument.parse(bodyString);

      if (param.typeOf != null) {
        // If a specific type is expected, convert XML to Map first
        final xmlMap = _xmlToMap(document.rootElement);
        return _deserializeToType(xmlMap, param.typeOf!);
      }

      // Return the XML document or convert to Map
      return _xmlToMap(document.rootElement);
    } catch (e) {
      throw BadRequestException('Invalid XML body: $e');
    }
  }

  /// Converts an XML element to a Map<String, dynamic>
  static Map<String, dynamic> _xmlToMap(XmlElement element) {
    final Map<String, dynamic> result = {};

    // Add attributes as properties with @ prefix
    for (final attribute in element.attributes) {
      result['@${attribute.name.local}'] = attribute.value;
    }

    // Process child elements
    final Map<String, List<dynamic>> children = {};

    for (final child in element.children) {
      if (child is XmlElement) {
        final childName = child.name.local;

        if (!children.containsKey(childName)) {
          children[childName] = [];
        }

        // If element has only text content, use the text value
        if (child.children.length == 1 && child.children.first is XmlText) {
          final textValue = child.innerText.trim();
          if (textValue.isNotEmpty) {
            children[childName]!.add(textValue);
          } else {
            children[childName]!.add(_xmlToMap(child));
          }
        } else {
          children[childName]!.add(_xmlToMap(child));
        }
      } else if (child is XmlText) {
        final textValue = child.value.trim();
        if (textValue.isNotEmpty) {
          result['#text'] = textValue;
        }
      }
    }

    // Convert single-item lists to direct values
    for (final entry in children.entries) {
      if (entry.value.length == 1) {
        result[entry.key] = entry.value.first;
      } else {
        result[entry.key] = entry.value;
      }
    }

    return result;
  }

  static Future<dynamic> _parseSparqlBody(
    Request request,
    Parameter param,
  ) async {
    var bodyString = await request.readAsString();
    bodyString = bodyString.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (bodyString.isEmpty) {
      throw BadRequestException('SPARQL body cannot be empty');
    }
    return bodyString;
  }

  static Future<dynamic> _parseFormUrlEncodedBody(
    Request request,
    Parameter param,
  ) async {
    try {
      final bodyString = await request.readAsString();

      if (bodyString.isEmpty) {
        return null;
      }

      // Parse form-urlencoded data
      final formData = Uri.splitQueryString(bodyString);

      if (param.typeOf != null) {
        return _deserializeToType(formData, param.typeOf!);
      }

      return formData;
    } catch (e) {
      throw BadRequestException('Invalid form-urlencoded body: $e');
    }
  }

  static Future<dynamic> _parseMultipartFormDataBody(
    Request request,
    Parameter param,
  ) async {
    try {
      // Check if the request is multipart by checking content-type
      final contentType = request.headers['content-type'];
      if (contentType == null || !contentType.contains('multipart/form-data')) {
        throw BadRequestException('Request is not multipart/form-data');
      }

      // Extract boundary from content-type header
      final boundary = _extractBoundary(contentType);
      if (boundary == null) {
        throw BadRequestException('Missing boundary in multipart/form-data');
      }

      final bodyBytes = await request.read().expand((chunk) => chunk).toList();
      final bodyString = utf8.decode(bodyBytes);

      final Map<String, dynamic> formData = {};

      // Split by boundary and process each part
      final parts = bodyString.split('--$boundary');

      for (final part in parts) {
        if (part.trim().isEmpty || part.trim() == '--') continue;

        final lines = part.split('\r\n');
        String? name;
        String? filename;
        bool isFile = false;
        int contentStartIndex = 0;

        // Parse headers
        for (int i = 0; i < lines.length; i++) {
          final line = lines[i].trim();
          if (line.isEmpty) {
            contentStartIndex = i + 1;
            break;
          }

          if (line.toLowerCase().startsWith('content-disposition:')) {
            final nameMatch = RegExp(r'name="([^"]*)"').firstMatch(line);
            if (nameMatch != null) {
              name = nameMatch.group(1);
            }

            final filenameMatch = RegExp(
              r'filename="([^"]*)"',
            ).firstMatch(line);
            if (filenameMatch != null) {
              filename = filenameMatch.group(1);
              isFile = true;
            }
          }
        }

        if (name == null) continue;

        // Skip file fields - they will be handled separately
        if (isFile || filename != null) {
          continue;
        }

        // Extract content
        final content = lines.sublist(contentStartIndex).join('\r\n').trim();

        // Handle multiple values with the same name (arrays)
        if (formData.containsKey(name)) {
          if (formData[name] is! List) {
            formData[name] = [formData[name]];
          }
          (formData[name] as List).add(content);
        } else {
          formData[name] = content;
        }
      }

      if (param.typeOf != null) {
        return _deserializeToType(formData, param.typeOf!);
      }

      return formData;
    } catch (e) {
      throw BadRequestException('Invalid multipart/form-data body: $e');
    }
  }

  /// Extracts the boundary from the Content-Type header
  static String? _extractBoundary(String contentType) {
    final boundaryMatch = RegExp(r'boundary=([^;]+)').firstMatch(contentType);
    return boundaryMatch?.group(1)?.replaceAll('"', '');
  }
}
