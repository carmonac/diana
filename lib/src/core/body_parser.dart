import 'package:diana/src/http/interfaces.dart';
import 'base/base.dart';
import 'content_type_registry.dart';
import 'handler_composer.dart';

class BodyParser {
  static Future<Object> parseBodyParameter(
    DianaRequest request,
    Parameter param,
  ) async {
    final contentType = request.contentType ?? 'text/plain';
    final contentTypeHandler = ContentTypeRegistry.getContentTypeHandler(
      contentType,
    );
    if (contentTypeHandler == null) {
      throw Exception('Unsupported content type: $contentType');
    }
    if (contentTypeHandler is! Deserializable) {
      throw Exception('Content type handler does not support deserialization');
    }

    final bodyObject = await (contentTypeHandler as Deserializable).deserialize(
      request,
      param.typeOf!,
    );

    return bodyObject;
  }

  static Future<List<Object>> parseBodyListParameter(
    DianaRequest request,
    Parameter param,
  ) async {
    final contentType = request.contentType ?? 'text/plain';
    final contentTypeHandler = ContentTypeRegistry.getContentTypeHandler(
      contentType,
    );
    if (contentTypeHandler == null) {
      throw Exception('Unsupported content type: $contentType');
    }
    if (contentTypeHandler is! Deserializable) {
      throw Exception('Content type handler does not support deserialization');
    }

    final bodyListObject = await (contentTypeHandler as Deserializable)
        .deserialize(request, List<Object>);

    return bodyListObject;
  }
}
