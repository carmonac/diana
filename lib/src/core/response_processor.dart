import 'package:diana/src/core/base/serializer.dart';
import 'package:diana/src/core/content_type_registry.dart';
import 'package:diana/src/core/no_content.dart';
import 'package:diana/src/http/interfaces.dart';

class ResponseProcessor {
  static DianaResponse processResponse(
    dynamic result,
    String acceptType,
    DianaResponseFactory responseFactory,
  ) {
    if (result is DianaResponse) {
      return result;
    } else if (result is String) {
      return responseFactory.text(result);
    } else if (result is NoContent) {
      return responseFactory.noContent();
    } else if (result == null) {
      return responseFactory.ok(null);
    } else {
      final contentTypeHandler = ContentTypeRegistry.getContentTypeHandler(
        acceptType,
      );

      if (contentTypeHandler == null || contentTypeHandler is! Serializable) {
        return responseFactory.text(result.toString());
      }
      try {
        return responseFactory.create(
          statusCode: 200,
          body: (contentTypeHandler as Serializable).serialize(result),
          headers: {'Content-Type': acceptType},
        );
      } catch (e) {
        print('Failed to serialize response: $e');
        return responseFactory.text(result.toString());
      }
    }
  }
}
