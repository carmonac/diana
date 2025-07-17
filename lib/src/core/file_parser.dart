import 'package:diana/src/core/base/base.dart';
import 'package:diana/src/core/content_type_registry.dart';
import 'package:diana/src/core/file_data.dart';
import 'package:diana/src/core/handler_composer.dart';
import 'package:diana/src/http/interfaces.dart';

class FileParser {
  static Future<dynamic> parseFileParameter(
    DianaRequest request,
    Parameter param,
  ) async {
    final contentType =
        request.header('content-type') ?? 'application/octet-stream';
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

    final bodyObject = await (contentTypeHandler as Deserializable).deserialize(
      request,
      FileData,
    );

    return bodyObject is FileData
        ? bodyObject
        : throw Exception('Deserialized body is not of type FileData');
  }
}
