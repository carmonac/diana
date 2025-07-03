import 'package:diana/src/adapter/request.dart';
import 'package:shelf/shelf.dart';
import '../core/base/base.dart';
import '../core/content_type_registry.dart';
import '../core/handler_composer.dart';

class BodyParser {
  static Future<Object> parseBodyParameter(
    Request request,
    Parameter param,
  ) async {
    final contentType = request.headers['content-type'] ?? 'text/plain';
    final contentTypeHandler = ContentTypeRegistry.getContentTypeHandler(
      contentType,
    );
    if (contentTypeHandler == null) {
      throw Exception('Unsupported content type: $contentType');
    }
    if (contentTypeHandler is! Deserializable) {
      throw Exception('Content type handler does not support deserialization');
    }

    final DianaRequest dianaRequest = DianaRequest.fromShelf(request);
    final bodyObject = await (contentTypeHandler as Deserializable).deserialize(
      dianaRequest,
      param.typeOf!,
    );

    return bodyObject;
  }

  static Future<List<Object>> parseBodyListParameter(
    Request request,
    Parameter param,
  ) async {
    final contentType = request.headers['content-type'] ?? 'text/plain';
    final contentTypeHandler = ContentTypeRegistry.getContentTypeHandler(
      contentType,
    );
    if (contentTypeHandler == null) {
      throw Exception('Unsupported content type: $contentType');
    }
    if (contentTypeHandler is! Deserializable) {
      throw Exception('Content type handler does not support deserialization');
    }

    final DianaRequest dianaRequest = DianaRequest.fromShelf(request);
    final bodyListObject = await (contentTypeHandler as Deserializable)
        .deserialize(dianaRequest, List<Object>);

    return bodyListObject;
  }
}
