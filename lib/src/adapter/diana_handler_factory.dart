import 'package:shelf/shelf.dart';
import 'request.dart';
import 'middleware_factory.dart';
import 'controller_handler_factory.dart';

/// Main handler factory for Diana framework
class DianaHandlerFactory {
  /// Creates a basic controller handler
  static Handler createControllerHandler<T extends Function>(
    T action,
    List<dynamic> params,
  ) {
    return ControllerHandlerFactory.createHandler(action, params);
  }

  /// Creates an optimized controller handler based on parameter count
  static Handler createOptimizedControllerHandler<T extends Function>(
    T action,
    List<dynamic> params,
  ) {
    return ControllerHandlerFactory.createOptimizedHandler(action, params);
  }

  /// Creates a guard middleware
  static Middleware createGuard(
    Future<DianaRequest> Function(DianaRequest) handler,
  ) {
    return MiddlewareFactory.createGuard(handler);
  }

  /// Creates a Diana middleware
  static Middleware createMiddleware(
    Future<DianaRequest> Function(DianaRequest) middlewareUseMethod,
  ) {
    return MiddlewareFactory.createMiddleware(middlewareUseMethod);
  }

  /// Creates an interceptor middleware
  static Middleware createInterceptor(
    Future<DianaRequest> Function(DianaRequest) interceptorUseMethod,
  ) {
    return MiddlewareFactory.createInterceptor(interceptorUseMethod);
  }
}
