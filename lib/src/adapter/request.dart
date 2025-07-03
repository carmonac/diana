import 'dart:io';

import 'package:shelf/shelf.dart' as shelf;

/// Diana framework HTTP request abstraction
class DianaRequest {
  final shelf.Request _shelfRequest;

  DianaRequest._(this._shelfRequest);

  /// Factory constructor from Shelf request
  factory DianaRequest.fromShelf(shelf.Request request) =>
      DianaRequest._(request);

  /// HTTP method (GET, POST, etc.)
  String get method => _shelfRequest.method;

  /// Request URI
  Uri get uri => _shelfRequest.requestedUri;

  /// Request headers
  Map<String, String> get headers => _shelfRequest.headers;

  /// Request context for storing custom data
  Map<String, Object?> get context => _shelfRequest.context;

  /// Query parameters
  Map<String, String> get queryParameters => _shelfRequest.url.queryParameters;

  /// Get content type
  String? get contentType => _shelfRequest.headers['content-type'];

  /// Get accept header
  String? get accept => _shelfRequest.headers['accept'];

  /// Read body as string
  Future<String> readAsString() => _shelfRequest.readAsString();

  /// Read body as bytes
  Future<List<int>> readAsBytes() =>
      _shelfRequest.read().expand((x) => x).toList();

  /// Read body as stream
  Stream<List<int>> read() => _shelfRequest.read();

  /// Get a specific header
  String? header(String name) => _shelfRequest.headers[name.toLowerCase()];

  /// Get context value
  T? getContext<T>(String key) => _shelfRequest.context[key] as T?;

  /// Get the client connection information
  /// Returns null if not available
  /// This is useful for getting client IP address, port, etc.
  HttpConnectionInfo? connectionInfo() =>
      (_shelfRequest.context['shelf.io.connection_info']
          as HttpConnectionInfo?);

  /// Create a copy with modified context
  DianaRequest copyWith({Map<String, Object?>? context}) {
    return DianaRequest._(
      _shelfRequest.change(
        context: context != null
            ? {..._shelfRequest.context, ...context}
            : null,
      ),
    );
  }

  /// Internal shelf request (for framework internal use only)
  shelf.Request get shelfRequest => _shelfRequest;
}
