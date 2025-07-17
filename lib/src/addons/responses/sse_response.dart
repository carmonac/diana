import 'package:diana/diana.dart';

class SseResponse {
  /// Creates a SSE response with the given [stream].
  /// Uses the globally configured response factory.
  static DianaResponse send(
    Stream<String> stream, {
    int statusCode = 200,
    Map<String, String>? headers,
  }) {
    final responseHeaders = <String, String>{
      'content-type': 'text/event-stream',
      'cache-control': 'no-cache',
      'connection': 'keep-alive',
      ...?headers,
    };

    return ResponseFactoryRegistry.factory.create(
      statusCode: statusCode,
      body: stream,
      headers: responseHeaders,
    );
  }
}
