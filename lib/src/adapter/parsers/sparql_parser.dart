import 'package:shelf/shelf.dart';

import '../../core/exceptions/exceptions.dart';
import '../../core/handler_composer.dart';

class SparqlParser {
  static Future<dynamic> parse(Request request, Parameter param) async {
    var bodyString = await request.readAsString();
    bodyString = bodyString.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (bodyString.isEmpty) {
      throw BadRequestException('SPARQL body cannot be empty');
    }
    return bodyString;
  }
}
