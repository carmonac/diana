import 'package:diana/src/core/base/base.dart';
import 'package:shelf/shelf.dart';
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
  static Middleware createGuard(DianaGuard guard) {
    return MiddlewareFactory.createGuard(guard);
  }

  /// Creates a Diana middleware
  static Middleware createMiddleware(DianaMiddleware middleware) {
    return MiddlewareFactory.createMiddleware(middleware);
  }

  /// Creates an interceptor middleware
  static Middleware createInterceptor(DianaInterceptor interceptor) {
    return MiddlewareFactory.createInterceptor(interceptor);
  }

  /// Middleware imported from shelf middleware
  static Middleware createShelfMiddleware(
    DianaShelfMiddleware dianaShelfMiddleware,
  ) {
    return dianaShelfMiddleware.adapter();
  }
}
