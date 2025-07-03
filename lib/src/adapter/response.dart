import 'package:shelf/shelf.dart' as shelf;

/// Diana framework HTTP response abstraction
class DianaResponse {
  final shelf.Response _shelfResponse;

  DianaResponse._(this._shelfResponse);

  /// Factory constructor from Shelf response
  factory DianaResponse.fromShelf(shelf.Response response) =>
      DianaResponse._(response);

  /// Create a successful response
  factory DianaResponse.ok(
    Object? body, {
    Map<String, String>? headers,
    String? contentType,
  }) {
    final responseHeaders = <String, String>{
      if (contentType != null) 'content-type': contentType,
      ...?headers,
    };

    return DianaResponse._(
      shelf.Response.ok(
        body,
        headers: responseHeaders.isNotEmpty ? responseHeaders : null,
      ),
    );
  }

  /// Create a text response
  factory DianaResponse.text(
    String body, {
    int statusCode = 200,
    Map<String, String>? headers,
  }) {
    return DianaResponse._(
      shelf.Response(
        statusCode,
        body: body,
        headers: {'content-type': 'text/plain', ...?headers},
      ),
    );
  }

  /// Create SSE (Server-Sent Events) response
  factory DianaResponse.sse(
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
    return DianaResponse._(
      shelf.Response(statusCode, body: stream, headers: responseHeaders),
    );
  }

  /// Create a redirect response
  factory DianaResponse.redirect(
    String location, {
    int statusCode = 302,
    Map<String, String>? headers,
  }) {
    final responseHeaders = <String, String>{'location': location, ...?headers};
    return DianaResponse._(
      shelf.Response(
        statusCode,
        headers: responseHeaders.isNotEmpty ? responseHeaders : null,
      ),
    );
  }

  /// Create a no content response
  factory DianaResponse.noContent({Map<String, String>? headers}) {
    return DianaResponse._(shelf.Response(204, headers: headers));
  }

  /// Response not found
  factory DianaResponse.notFound([String? message]) {
    return DianaResponse._(shelf.Response.notFound(message));
  }

  /// Response internal server error
  factory DianaResponse.internalServerError([String? message]) {
    return DianaResponse._(shelf.Response.internalServerError(body: message));
  }

  /// Create a found response (HTTP 302)
  factory DianaResponse.found(String location, {Map<String, String>? headers}) {
    return DianaResponse._(shelf.Response.found(location, headers: headers));
  }

  /// Create a custom response
  factory DianaResponse(
    int statusCode, {
    Object? body,
    Map<String, String>? headers,
  }) {
    return DianaResponse._(
      shelf.Response(statusCode, body: body, headers: headers),
    );
  }

  /// Response status code
  int get statusCode => _shelfResponse.statusCode;

  /// Response headers
  Map<String, String> get headers => _shelfResponse.headers;

  /// Internal shelf response (for framework internal use only)
  shelf.Response get shelfResponse => _shelfResponse;
}
