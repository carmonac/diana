import '..//core/exceptions/exceptions.dart';
import 'package:shelf/shelf.dart';
import '../core/base/base.dart';
import 'request.dart';
import 'response.dart';

class MiddlewareFactory {
  static Middleware createGuard(DianaGuard guard) {
    return (Handler nextHandler) {
      return (Request request) async {
        final result = await guard.canActivate(DianaRequest.fromShelf(request));
        if (result) {
          return nextHandler(request);
        } else {
          throw ForbiddenException("Access denied");
        }
      };
    };
  }

  static Middleware createMiddleware(DianaMiddleware middleware) {
    return (Handler nextHandler) {
      return (Request shelfRequest) async {
        final dianaRequest = DianaRequest.fromShelf(shelfRequest);

        Future<DianaResponse> dianaNext(DianaRequest request) async {
          final shelfResponse = await nextHandler(request.shelfRequest);
          return DianaResponse.fromShelf(shelfResponse);
        }

        final dianaResponse = await middleware.use(dianaRequest, dianaNext);

        return dianaResponse.shelfResponse;
      };
    };
  }

  static Middleware createInterceptor(DianaInterceptor interceptor) {
    return (Handler nextHandler) {
      return (Request shelfRequest) async {
        final dianaRequest = DianaRequest.fromShelf(shelfRequest);

        await interceptor.onRequest(dianaRequest);

        final shelfResponse = await nextHandler(dianaRequest.shelfRequest);
        final dianaResponse = DianaResponse.fromShelf(shelfResponse);

        await interceptor.onResponse(dianaResponse);

        return dianaResponse.shelfResponse;
      };
    };
  }
}
