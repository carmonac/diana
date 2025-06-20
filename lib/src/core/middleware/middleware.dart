import 'package:shelf/shelf.dart' as shelf;

import '../http/handler.dart';
import '../http/request.dart';
import '../http/response.dart';

/// Abstract base class for creating custom middleware in Diana framework
abstract class DianaMiddleware {
  /// Process the request and optionally call the next handler
  ///
  /// [request] - The incoming HTTP request
  /// [next] - The next handler in the pipeline
  ///
  /// Returns a [DianaResponse] that will be sent to the client
  Future<DianaResponse> handle(DianaRequest request, DianaHandler next);
}

/// Utility class to convert Diana middleware to Shelf middleware
class MiddlewareAdapter {
  /// Convert Diana middleware to Shelf middleware
  static shelf.Middleware adapt(DianaMiddleware middleware) {
    return createShelfMiddleware(middleware);
  }
}

/// Creates a Shelf middleware from a Diana middleware
shelf.Middleware createShelfMiddleware(DianaMiddleware middleware) {
  return (shelf.Handler handler) {
    return createRequestHandler(middleware, handler);
  };
}

/// Creates a request handler that wraps Diana middleware
Future<shelf.Response> Function(shelf.Request) createRequestHandler(
  DianaMiddleware middleware,
  shelf.Handler handler,
) {
  return (shelf.Request request) async {
    final dianaRequest = DianaRequest.fromShelf(request);
    final dianaHandler = createDianaHandler(handler);

    final response = await middleware.handle(dianaRequest, dianaHandler);
    return response.shelfResponse;
  };
}

/// Creates a Diana handler from a Shelf handler
DianaHandler createDianaHandler(shelf.Handler handler) {
  return (DianaRequest req) async {
    final shelfResponse = await handler(req.shelfRequest);
    return DianaResponse.fromShelf(shelfResponse);
  };
}
