import 'package:diana/diana.dart';

class JsonResponse {
  /// Creates a JSON response with the given [data].
  /// Uses the globally configured response factory.
  static DianaResponse send(
    dynamic data, {
    int statusCode = 200,
    Map<String, String>? headers,
  }) {
    final contentType = 'application/json';
    final serializer =
        ContentTypeRegistry.getContentTypeHandler(contentType) as Serializable;

    return ResponseFactoryRegistry.factory.create(
      statusCode: statusCode,
      body: serializer.serialize(data),
      headers: {'Content-Type': contentType, ...?headers},
    );
  }
}
