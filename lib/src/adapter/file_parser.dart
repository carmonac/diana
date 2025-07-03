import '../core/base/base.dart';
import '../core/content_type_registry.dart';
import 'package:shelf/shelf.dart';
import '../core/file_data.dart';
import '../core/handler_composer.dart';
import 'request.dart';

class FileParser {
  static Future<dynamic> parseFileParameter(
    Request request,
    Parameter param,
  ) async {
    final contentType =
        request.headers['content-type'] ?? 'application/octet-stream';
    final contentTypeHandler = ContentTypeRegistry.getContentTypeHandler(
      contentType,
    );
    if (contentTypeHandler == null) {
      throw Exception('Unsupported content type: $contentType');
    }
    if (contentTypeHandler is! Deserializable) {
      throw Exception('Content type handler does not support deserialization');
    }
    if (param.typeOf is! FileData) {
      throw Exception('Parameter type must be FileData for file parsing');
    }

    final DianaRequest dianaRequest = DianaRequest.fromShelf(request);
    final bodyObject = await (contentTypeHandler as Deserializable).deserialize(
      dianaRequest,
      FileData,
    );

    return bodyObject is FileData
        ? bodyObject
        : throw Exception('Deserialized body is not of type FileData');
  }
}
