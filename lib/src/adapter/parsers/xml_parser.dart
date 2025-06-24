import 'package:shelf/shelf.dart';
import 'package:xml/xml.dart';

import '../../core/exceptions/exceptions.dart';
import '../../core/handler_composer.dart';
import '../../core/utils.dart';

class XmlParser {
  static Future<dynamic> parse(Request request, Parameter param) async {
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
        return deserializeToType(xmlMap, param.typeOf!);
      }

      // Return the XML document or convert to Map
      return _xmlToMap(document.rootElement);
    } catch (e) {
      throw BadRequestException('Invalid XML body: $e');
    }
  }

  /// Converts an XML element to a Map&ltString, dynamic&gt;
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
}
