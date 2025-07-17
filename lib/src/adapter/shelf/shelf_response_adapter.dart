import 'package:diana/src/http/interfaces.dart';
import 'package:shelf/shelf.dart' as shelf;

class ShelfResponseAdapter implements DianaResponse {
  final shelf.Response _response;

  ShelfResponseAdapter._(this._response);

  /// Factory constructor from Shelf response
  factory ShelfResponseAdapter.fromShelf(shelf.Response response) =>
      ShelfResponseAdapter._(response);

  shelf.Response get shelfResponse => _response;

  @override
  Object? get body => _response.read();

  @override
  String? get contentType => _response.headers['content-type'];

  @override
  Map<String, String> get headers => _response.headers;

  @override
  int get statusCode => _response.statusCode;

  @override
  DianaResponse copyWith({
    int? statusCode,
    Map<String, String>? headers,
    Object? body,
  }) {
    return ShelfResponseAdapter._(
      shelf.Response(
        statusCode ?? _response.statusCode,
        headers: headers ?? _response.headers,
        body: body ?? _response.read(),
      ),
    );
  }

  @override
  DianaResponse withHeader(String name, String value) {
    final newHeaders = Map<String, String>.from(_response.headers);
    newHeaders[name] = value;
    return ShelfResponseAdapter._(
      shelf.Response(
        _response.statusCode,
        headers: newHeaders,
        body: _response.read(),
      ),
    );
  }

  @override
  DianaResponse withHeaders(Map<String, String> headers) {
    final newHeaders = Map<String, String>.from(_response.headers);
    newHeaders.addAll(headers);
    return ShelfResponseAdapter._(
      shelf.Response(
        _response.statusCode,
        headers: newHeaders,
        body: _response.read(),
      ),
    );
  }

  @override
  DianaResponse withContentType(String contentType) {
    return withHeader('content-type', contentType);
  }

  @override
  DianaResponse withStatus(int statusCode) {
    return ShelfResponseAdapter._(
      shelf.Response(
        statusCode,
        headers: _response.headers,
        body: _response.read(),
      ),
    );
  }

  @override
  bool get isSuccess => statusCode >= 200 && statusCode < 300;

  @override
  bool get isRedirect => statusCode >= 300 && statusCode < 400;

  @override
  bool get isClientError => statusCode >= 400 && statusCode < 500;

  @override
  bool get isServerError => statusCode >= 500;

  @override
  bool get isError => statusCode >= 400;

  @override
  DianaResponse change({
    Map<String, Object?>? headers,
    Map<String, Object?>? context,
    Object? body,
  }) {
    _response.change(
      headers: headers ?? _response.headers,
      context: context ?? _response.context,
      body: body ?? _response.read(),
    );
    return this;
  }
}
