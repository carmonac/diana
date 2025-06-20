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

  /// Create a JSON response
  factory DianaResponse.json(
    Object? data, {
    int statusCode = 200,
    Map<String, String>? headers,
  }) {
    return DianaResponse._(
      shelf.Response(
        statusCode,
        body: data
            ?.toString(), // En una implementación real usarías json.encode
        headers: {'content-type': 'application/json', ...?headers},
      ),
    );
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

  /// Create a not found response
  factory DianaResponse.notFound([String? message]) {
    return DianaResponse._(shelf.Response.notFound(message));
  }

  /// Create an internal server error response
  factory DianaResponse.internalServerError([String? message]) {
    return DianaResponse._(shelf.Response.internalServerError(body: message));
  }

  /// Response status code
  int get statusCode => _shelfResponse.statusCode;

  /// Response headers
  Map<String, String> get headers => _shelfResponse.headers;

  /// Internal shelf response (for framework internal use only)
  shelf.Response get shelfResponse => _shelfResponse;
}
