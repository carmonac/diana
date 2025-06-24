import 'package:shelf/shelf.dart';
import 'package:yaml/yaml.dart';

import '../../core/exceptions/exceptions.dart';
import '../../core/handler_composer.dart';
import '../../core/utils.dart';

class YamlParser {
  static Future<dynamic> parse(Request request, Parameter param) async {
    try {
      final bodyString = await request.readAsString();

      if (bodyString.isEmpty) {
        return null;
      }

      // Parse YAML data
      final yamlData = loadYaml(bodyString);

      // Convert YamlMap/YamlList to regular Dart objects
      final convertedData = _convertYamlToDart(yamlData);

      if (param.typeOf != null && convertedData is Map<String, dynamic>) {
        return deserializeToType(convertedData, param.typeOf!);
      }

      return convertedData;
    } catch (e) {
      throw BadRequestException('Invalid YAML body: $e');
    }
  }

  /// Converts YAML objects to regular Dart objects
  static dynamic _convertYamlToDart(dynamic yamlData) {
    if (yamlData is YamlMap) {
      final Map<String, dynamic> result = {};
      for (final entry in yamlData.entries) {
        result[entry.key.toString()] = _convertYamlToDart(entry.value);
      }
      return result;
    } else if (yamlData is YamlList) {
      return yamlData.map(_convertYamlToDart).toList();
    } else {
      return yamlData;
    }
  }
}
