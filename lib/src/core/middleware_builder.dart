import 'package:diana/src/core/base/base.dart';
import 'package:diana/src/core/exceptions/exceptions.dart';
import 'package:diana/src/http/interfaces.dart';

class MiddlewareBuilder {
  static DianaMiddleware buildGuard(AbstractGuard guard) {
    return (DianaHandler nextHandler) {
      return (DianaRequest request) async {
        final result = await guard.canActivate(request);
        if (result) {
          return nextHandler(request);
        } else {
          throw ForbiddenException("Access denied");
        }
      };
    };
  }

  static DianaMiddleware buildMiddleware(AbstractMiddleware middleware) {
    return (DianaHandler nextHandler) {
      return (DianaRequest request) async {
        Future<DianaResponse> dianaNext(DianaRequest req) async {
          return await nextHandler(req);
        }

        return await middleware.use(request, dianaNext);
      };
    };
  }

  static DianaMiddleware buildInterceptor(AbstractInterceptor interceptor) {
    return (DianaHandler nextHandler) {
      return (DianaRequest request) async {
        await interceptor.onRequest(request);

        final response = await nextHandler(request);

        await interceptor.onResponse(response);

        return response;
      };
    };
  }
}
