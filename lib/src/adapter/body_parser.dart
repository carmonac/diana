import './parsers/parsers.dart';
import 'package:shelf/shelf.dart';
import '../core/handler_composer.dart';

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
      return await JsonParser.parse(request, param);
    }

    if (contentType.toLowerCase().contains('application/xml') ||
        contentType.toLowerCase().contains('text/xml')) {
      return await XmlParser.parse(request, param);
    }

    if (contentType.toLowerCase().contains('application/sparql-query') ||
        contentType.toLowerCase().contains('application/sparql-update')) {
      return await SparqlParser.parse(request, param);
    }

    // x-www-form-urlencoded
    if (contentType.toLowerCase().contains(
      'application/x-www-form-urlencoded',
    )) {
      return await FormUrlEncodeParser.parse(request, param);
    }

    // multipart/form-data
    if (contentType.toLowerCase().contains('multipart/form-data')) {
      return await MultipartFormDataParser.parse(request, param);
    }

    // CSV
    if (contentType.toLowerCase().contains('text/csv') ||
        contentType.toLowerCase().contains('application/csv')) {
      return await CsvParser.parse(request, param);
    }

    // YAML
    if (contentType.toLowerCase().contains('application/yaml') ||
        contentType.toLowerCase().contains('text/yaml') ||
        contentType.toLowerCase().contains('application/x-yaml')) {
      return await YamlParser.parse(request, param);
    }

    // Protocol Buffers
    if (contentType.toLowerCase().contains('application/x-protobuf') ||
        contentType.toLowerCase().contains('application/protobuf')) {
      return await ProtobufParser.parse(request, param);
    }

    // MessagePack
    if (contentType.toLowerCase().contains('application/x-msgpack') ||
        contentType.toLowerCase().contains('application/msgpack')) {
      return await MessagePackParser.parse(request, param);
    }

    if (contentType.toLowerCase().contains('text/plain')) {
      return await request.readAsString();
    }

    return await request.readAsString();
  }
}
