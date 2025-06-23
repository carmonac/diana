import 'package:shelf/shelf.dart';
import 'request.dart';
import 'response.dart';
import 'handler.dart';

class MiddlewareFactory {
  static Middleware createGuard(Function handler) {
    return (Handler nextHandler) {
      return (Request request) async {
        final result = await (handler as Future<bool> Function(Request))(
          request,
        );
        if (result) {
          return nextHandler(request);
        } else {
          return Response.forbidden('Access denied');
        }
      };
    };
  }

  static Middleware createMiddleware(Function middlewareUseMethod) {
    return (Handler nextHandler) {
      return (Request shelfRequest) async {
        final dianaRequest = DianaRequest.fromShelf(shelfRequest);

        Future<DianaResponse> dianaNext(DianaRequest request) async {
          final shelfResponse = await nextHandler(request.shelfRequest);
          return DianaResponse.fromShelf(shelfResponse);
        }

        final dianaResponse =
            await (middlewareUseMethod
                as Future<DianaResponse> Function(DianaRequest, DianaHandler))(
              dianaRequest,
              dianaNext,
            );

        return dianaResponse.shelfResponse;
      };
    };
  }

  static Middleware createInterceptor(
    Future<DianaRequest> Function(DianaRequest) interceptorUseMethod,
  ) {
    return (Handler nextHandler) {
      return (Request shelfRequest) async {
        final dianaRequest = DianaRequest.fromShelf(shelfRequest);
        final modifiedDianaRequest = await interceptorUseMethod(dianaRequest);
        final shelfResponse = await nextHandler(
          modifiedDianaRequest.shelfRequest,
        );
        return shelfResponse;
      };
    };
  }
}
