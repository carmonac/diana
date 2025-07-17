import 'package:diana/diana.dart';

class TextResponse {
  /// Creates a text response with the given [body].
  /// Uses the globally configured response factory.
  static DianaResponse send(
    String body, {
    int statusCode = 200,
    Map<String, String>? headers,
  }) {
    return ResponseFactoryRegistry.factory.create(
      statusCode: statusCode,
      body: body,
      headers: {'content-type': 'text/plain', ...?headers},
    );
  }
}
