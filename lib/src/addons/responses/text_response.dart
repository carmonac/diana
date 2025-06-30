import 'package:diana/diana.dart';

class TextResponse {
  /// Creates a SSE response with the given [stream].
  static DianaResponse send(
    String body, {
    int statusCode = 200,
    Map<String, String>? headers,
  }) {
    return DianaResponse(
      statusCode,
      body: body,
      headers: {'content-type': 'text/plain', ...?headers},
    );
  }
}
