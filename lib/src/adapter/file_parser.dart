import './parsers/parsers.dart';
import 'package:shelf/shelf.dart';
import '../core/handler_composer.dart';

class FileParser {
  static Future<dynamic> parseFileParameter(
    Request request,
    Parameter param,
  ) async {
    final contentType = request.headers['content-type'];

    if (contentType == null) {
      return null;
    }

    // multipart/form-data for file uploads
    if (contentType.toLowerCase().contains('multipart/form-data')) {
      return await MultipartFileParser.parse(request, param);
    }

    // application/octet-stream for binary file uploads
    if (contentType.toLowerCase().contains('application/octet-stream')) {
      return await OctetStreamParser.parse(request, param);
    }

    return null;
  }
}
