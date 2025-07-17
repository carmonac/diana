import 'package:diana/src/core/base/base.dart';
import 'package:diana/src/core/static_options.dart';
import 'package:diana/src/http/interfaces.dart';
import 'package:shelf/shelf.dart' as shelf;
import 'http_handler_builder.dart';
import '../adapter/shelf/shelf_middleware_builder.dart';

/// Main handler factory for Diana framework
class DianaHandlerFactory {
  /// Allows users to configure a different middleware adapter
  static DianaMiddlewareAdapterFactory middlewareAdapter =
      ShelfMiddlewareBuilder();

  /// Creates an optimized controller handler based on parameter count
  static DianaHandler createControllerHandler<T extends Function>(
    T action,
    List<dynamic> params, {
    required String outputContentType,
    required DianaResponseFactory responseFactory,
  }) {
    return DianaHandlerBuilder.buildOptimizedHandler(
      action,
      params,
      outputContentType: outputContentType,
      responseFactory: responseFactory,
    );
  }

  /// Creates static file server handler
  static DianaHandler createStaticFileServer(
    StaticOptions staticOptions,
    DianaStaticFileServerFactory staticFileServerFactory,
  ) {
    return DianaHandlerBuilder.buildStaticFileServerHandler(
      staticOptions.path,
      defaultDocument: staticOptions.defaultDocument,
      listDirectory: staticOptions.listDirectory,
      staticFileServerFactory: staticFileServerFactory,
    );
  }

  /// Creates a guard middleware using the configured adapter
  static shelf.Middleware createGuard(AbstractGuard guard) {
    return middlewareAdapter.createGuardMiddleware(guard) as shelf.Middleware;
  }

  /// Creates a Diana middleware using the configured adapter
  static shelf.Middleware createMiddleware(AbstractMiddleware middleware) {
    return middlewareAdapter.createMiddleware(middleware) as shelf.Middleware;
  }

  /// Creates an interceptor middleware using the configured adapter
  static shelf.Middleware createInterceptor(AbstractInterceptor interceptor) {
    return middlewareAdapter.createInterceptorMiddleware(interceptor)
        as shelf.Middleware;
  }

  /// Middleware imported from shelf middleware
  static shelf.Middleware createShelfMiddleware(
    AbstractShelfMiddleware dianaShelfMiddleware,
  ) {
    return dianaShelfMiddleware.adapter();
  }
}
