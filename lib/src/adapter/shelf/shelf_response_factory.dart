import 'dart:convert';
import 'package:diana/src/http/interfaces.dart';
import 'package:shelf/shelf.dart' as shelf;
import 'shelf_response_adapter.dart';

class ShelfResponseFactory implements DianaResponseFactory {
  @override
  DianaResponse create({
    required int statusCode,
    Map<String, String>? headers,
    Object? body,
  }) {
    return ShelfResponseAdapter.fromShelf(
      shelf.Response(statusCode, headers: headers, body: body),
    );
  }

  @override
  DianaResponse ok(
    Object? body, {
    Map<String, String>? headers,
    String? contentType,
  }) {
    final responseHeaders = <String, String>{
      if (contentType != null) 'content-type': contentType,
      ...?headers,
    };

    return ShelfResponseAdapter.fromShelf(
      shelf.Response.ok(
        body,
        headers: responseHeaders.isNotEmpty ? responseHeaders : null,
      ),
    );
  }

  @override
  DianaResponse text(
    String body, {
    int statusCode = 200,
    Map<String, String>? headers,
  }) {
    return ShelfResponseAdapter.fromShelf(
      shelf.Response(
        statusCode,
        body: body,
        headers: {'content-type': 'text/plain', ...?headers},
      ),
    );
  }

  @override
  DianaResponse json(
    Object? body, {
    int statusCode = 200,
    Map<String, String>? headers,
  }) {
    return ShelfResponseAdapter.fromShelf(
      shelf.Response(
        statusCode,
        body: jsonEncode(body),
        headers: {'content-type': 'application/json', ...?headers},
      ),
    );
  }

  @override
  DianaResponse html(
    String body, {
    int statusCode = 200,
    Map<String, String>? headers,
  }) {
    return ShelfResponseAdapter.fromShelf(
      shelf.Response(
        statusCode,
        body: body,
        headers: {'content-type': 'text/html', ...?headers},
      ),
    );
  }

  @override
  DianaResponse redirect(
    String location, {
    int statusCode = 302,
    Map<String, String>? headers,
  }) {
    final responseHeaders = <String, String>{'location': location, ...?headers};
    return ShelfResponseAdapter.fromShelf(
      shelf.Response(
        statusCode,
        headers: responseHeaders.isNotEmpty ? responseHeaders : null,
      ),
    );
  }

  @override
  DianaResponse noContent({Map<String, String>? headers}) {
    return ShelfResponseAdapter.fromShelf(
      shelf.Response(204, headers: headers),
    );
  }

  @override
  DianaResponse notFound([String? message]) {
    return ShelfResponseAdapter.fromShelf(shelf.Response.notFound(message));
  }

  @override
  DianaResponse internalServerError([String? message]) {
    return ShelfResponseAdapter.fromShelf(
      shelf.Response.internalServerError(body: message),
    );
  }

  @override
  DianaResponse badRequest([String? message]) {
    return ShelfResponseAdapter.fromShelf(shelf.Response(400, body: message));
  }

  @override
  DianaResponse unauthorized([String? message]) {
    return ShelfResponseAdapter.fromShelf(shelf.Response(401, body: message));
  }

  @override
  DianaResponse forbidden([String? message]) {
    return ShelfResponseAdapter.fromShelf(shelf.Response(403, body: message));
  }

  @override
  DianaResponse sse(
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
    return ShelfResponseAdapter.fromShelf(
      shelf.Response(statusCode, body: stream, headers: responseHeaders),
    );
  }
}
