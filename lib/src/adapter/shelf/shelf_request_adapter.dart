import 'dart:io';

import 'package:diana/src/http/interfaces.dart';
import 'package:shelf/shelf.dart' as shelf;

class ShelfRequestAdapter implements DianaRequest {
  final shelf.Request _request;

  ShelfRequestAdapter(this._request);

  @override
  String get method => _request.method;

  @override
  Uri get uri => _request.requestedUri;

  @override
  T? getContext<T>(String key) => _request.context[key] as T?;

  @override
  Map<String, String> get headers => _request.headers;

  @override
  Map<String, String> get queryParameters => _request.url.queryParameters;

  @override
  Future<String> readAsString() => _request.readAsString();

  @override
  Map<String, Object?> get context => _request.context;

  @override
  Future<List<int>> readAsBytes() => _request.read().expand((x) => x).toList();

  @override
  Stream<List<int>> readAsStream() => _request.read();

  @override
  String? get accept => _request.headers['accept'];

  @override
  HttpConnectionInfo? connectionInfo() {
    // Shelf does not expose connection info directly
    // This is a workaround to get client connection info if available
    return _request.context['shelf.io.connection_info'] as HttpConnectionInfo?;
  }

  @override
  String? get contentType => _request.headers['content-type'];

  @override
  DianaRequest copyWith({Map<String, Object?>? context}) {
    return ShelfRequestAdapter(
      _request.change(context: {..._request.context, ...?context}),
    );
  }

  @override
  String? header(String name) => _request.headers[name.toLowerCase()];

  @override
  Map<String, List<String>> get queryParametersAll =>
      _request.url.queryParametersAll;

  @override
  String get host => _request.headers['host'] ?? _request.requestedUri.host;

  @override
  DianaRequest change({
    Map<String, Object?>? headers,
    Map<String, Object?>? context,
    String? path,
    Object? body,
  }) {
    _request.change(
      headers: headers ?? _request.headers,
      context: context ?? _request.context,
      path: path ?? _request.requestedUri.path,
      body: body ?? _request.read(),
    );
    return this;
  }

  /// Access to underlying Shelf request (for framework internal use only)
  shelf.Request get shelfRequest => _request;
}
