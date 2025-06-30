import 'package:shelf/shelf.dart';
import '../core/base/serializer.dart';
import '../core/content_type_registry.dart';
import '../core/no_content.dart';

import 'response.dart';

class ResponseProcessor {
  static DianaResponse processResponse(dynamic result, String acceptType) {
    if (result is DianaResponse) {
      return result;
    } else if (result is Response) {
      return DianaResponse.fromShelf(result);
    } else if (result is String) {
      return DianaResponse.text(result);
    } else if (result is NoContent) {
      return DianaResponse.noContent();
    } else if (result == null) {
      return DianaResponse.ok(null);
    } else {
      final contentTypeHandler = ContentTypeRegistry.getContentTypeHandler(
        acceptType,
      );

      if (contentTypeHandler == null || contentTypeHandler is! Serializable) {
        return DianaResponse.text(result.toString());
      }
      try {
        return DianaResponse(
          200,
          body: (contentTypeHandler as Serializable).serialize(result),
          headers: {'Content-Type': acceptType},
        );
      } catch (e) {
        print('Failed to serialize response: $e');
        return DianaResponse.text(result.toString());
      }
    }
  }
}
