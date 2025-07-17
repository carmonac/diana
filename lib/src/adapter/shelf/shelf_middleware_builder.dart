import 'package:diana/src/core/base/base.dart';
import 'package:diana/src/core/exceptions/exceptions.dart';
import 'package:diana/src/core/middleware_builder.dart';
import 'package:diana/src/http/interfaces.dart';
import 'package:shelf/shelf.dart' as shelf;
import 'shelf_request_adapter.dart';
import 'shelf_response_adapter.dart';

/// Shelf-specific middleware builder
/// Implements DianaMiddlewareAdapterFactory to create Shelf middleware from Diana components
class ShelfMiddlewareBuilder implements DianaMiddlewareAdapterFactory {
  @override
  shelf.Middleware createGuardMiddleware(AbstractGuard guard) {
    return (shelf.Handler nextHandler) {
      return (shelf.Request request) async {
        final dianaRequest = ShelfRequestAdapter(request);
        final result = await guard.canActivate(dianaRequest);
        if (result) {
          return nextHandler(request);
        } else {
          throw ForbiddenException("Access denied");
        }
      };
    };
  }

  @override
  shelf.Middleware createMiddleware(AbstractMiddleware middleware) {
    // Build the Diana middleware function from the abstract middleware
    final dianaMiddleware = MiddlewareBuilder.buildMiddleware(middleware);

    return (shelf.Handler nextHandler) {
      return (shelf.Request shelfRequest) async {
        final dianaRequest = ShelfRequestAdapter(shelfRequest);

        Future<DianaResponse> httpNext(DianaRequest request) async {
          // Convert back to shelf request for the next handler
          final shelfReq = (request as ShelfRequestAdapter).shelfRequest;
          final shelfResponse = await nextHandler(shelfReq);
          return ShelfResponseAdapter.fromShelf(shelfResponse);
        }

        final dianaResponse = await dianaMiddleware(httpNext)(dianaRequest);

        // Convert Diana response back to Shelf response
        return (dianaResponse as ShelfResponseAdapter).shelfResponse;
      };
    };
  }

  @override
  shelf.Middleware createInterceptorMiddleware(
    AbstractInterceptor interceptor,
  ) {
    return (shelf.Handler nextHandler) {
      return (shelf.Request shelfRequest) async {
        final dianaRequest = ShelfRequestAdapter(shelfRequest);

        await interceptor.onRequest(dianaRequest);

        final shelfResponse = await nextHandler(shelfRequest);
        final dianaResponse = ShelfResponseAdapter.fromShelf(shelfResponse);

        await interceptor.onResponse(dianaResponse);

        return (dianaResponse).shelfResponse;
      };
    };
  }
}
