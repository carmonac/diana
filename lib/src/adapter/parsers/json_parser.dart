import 'dart:convert';

import 'package:shelf/shelf.dart';

import '../../core/exceptions/exceptions.dart';
import '../../core/handler_composer.dart';
import '../../core/utils.dart';

class JsonParser {
  static Future<dynamic> parse(Request request, Parameter param) async {
    try {
      final bodyString = await request.readAsString();

      if (bodyString.isEmpty) {
        return null;
      }

      if (param.typeOf != null) {
        final jsonMap = json.decode(bodyString) as Map<String, dynamic>;
        return deserializeToType(jsonMap, param.typeOf!);
      }

      return json.decode(bodyString);
    } catch (e) {
      throw BadRequestException('Invalid JSON body: $e');
    }
  }
}
