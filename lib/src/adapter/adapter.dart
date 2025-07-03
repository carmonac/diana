import 'dart:async';

import '../core/diana_config.dart';
import '../core/handler_composer.dart';
import '../core/utils.dart';
import 'diana_handler_factory.dart';
import 'request.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'error_response.dart';
import 'secure_cookie_handler.dart';
import 'secure_session_handler.dart';

class Adapter {
  final globalRouter = Router();
  final globalPipeline = Pipeline();
  final DianaConfig dianaConfig;

  Adapter({
    GlobalComposer? globalComposer,
    List<ControllerComposer> controllers = const [],
    DianaConfig? dianaConfig,
  }) : dianaConfig = dianaConfig ?? DianaConfig() {
    setUpGlobalPipeline(globalComposer);
    for (final controller in controllers) {
      setUpController(controller);
    }
  }

  void setUpGlobalPipeline([GlobalComposer? globalComposer]) {
    // Add redirect middlewares first
    if (dianaConfig.redirectHttpToHttps == true) {
      globalPipeline.addMiddleware(_httpToHttpsRedirectMiddleware);
    }

    if (dianaConfig.redirectTrailingSlash == true) {
      globalPipeline.addMiddleware(_trailingSlashRedirectMiddleware);
    }

    if (dianaConfig.cookieParserEnabled == true) {
      final cookieHandler = SecureCookieHandler(dianaConfig.cookieSecret);
      globalPipeline.addMiddleware(cookieHandler.middleware);
    }

    if (dianaConfig.sessionConfig != null) {
      final sessionHandler = SecureSessionHandler(
        dianaConfig.cookieSecret,
        config: dianaConfig.sessionConfig!,
      );
      globalPipeline.addMiddleware(sessionHandler.middleware);
    }

    globalPipeline.addMiddleware((Handler nextHandler) {
      return (Request request) async {
        final dianaRequest = DianaRequest.fromShelf(request);
        final modifiedRequest = dianaRequest.copyWith(
          context: {'request_id': generateRequestId()},
        );
        return await nextHandler(modifiedRequest.shelfRequest);
      };
    });
    if (dianaConfig.errorHandler != null) {
      globalPipeline.addMiddleware(
        ErrorResponse.customErrorResponse(dianaConfig.errorHandler!),
      );
    } else {
      globalPipeline.addMiddleware(
        ErrorResponse.dianaErrorResponse(
          dianaConfig.defaultOutputContentType,
          dianaConfig.errorBuilder,
        ),
      );
    }

    if (globalComposer == null) {
      return;
    }
    for (final component in globalComposer.components) {
      switch (component.type.toString()) {
        case 'DianaGuard':
          globalPipeline.addMiddleware(
            DianaHandlerFactory.createGuard(
              (component as GuardComponent).guard,
            ),
          );
          break;
        case 'DianaMiddleware':
          globalPipeline.addMiddleware(
            DianaHandlerFactory.createMiddleware(
              (component as MiddlewareComponent).middleware,
            ),
          );
          break;
        case 'DianaInterceptor':
          globalPipeline.addMiddleware(
            DianaHandlerFactory.createInterceptor(
              (component as InterceptorComponent).interceptor,
            ),
          );
          break;
        case 'DianaShelfMiddleware':
          globalPipeline.addMiddleware(
            DianaHandlerFactory.createShelfMiddleware(
              (component as ShelfMiddlewareComponent).dianaShelfMiddleware,
            ),
          );
          break;
      }
    }
  }

  void setUpController(ControllerComposer controllerComposer) {
    final router = Router();
    final Pipeline pipeline = Pipeline();
    for (final component in controllerComposer.components) {
      switch (component.type.toString()) {
        case 'DianaGuard':
          pipeline.addMiddleware(
            DianaHandlerFactory.createGuard(
              (component as GuardComponent).guard,
            ),
          );
          break;
        case 'DianaMiddleware':
          pipeline.addMiddleware(
            DianaHandlerFactory.createMiddleware(
              (component as MiddlewareComponent).middleware,
            ),
          );
          break;
        case 'DianaInterceptor':
          pipeline.addMiddleware(
            DianaHandlerFactory.createInterceptor(
              (component as InterceptorComponent).interceptor,
            ),
          );
          break;
        case 'DianaShelfMiddleware':
          pipeline.addMiddleware(
            DianaHandlerFactory.createShelfMiddleware(
              (component as ShelfMiddlewareComponent).dianaShelfMiddleware,
            ),
          );
          break;
      }
    }
    for (final route in controllerComposer.routes) {
      for (final component in route.components) {
        switch (component.type.toString()) {
          case 'DianaGuard':
            pipeline.addMiddleware(
              DianaHandlerFactory.createGuard(
                (component as GuardComponent).guard,
              ),
            );
            break;
          case 'DianaMiddleware':
            pipeline.addMiddleware(
              DianaHandlerFactory.createMiddleware(
                (component as MiddlewareComponent).middleware,
              ),
            );
            break;
          case 'DianaInterceptor':
            pipeline.addMiddleware(
              DianaHandlerFactory.createInterceptor(
                (component as InterceptorComponent).interceptor,
              ),
            );
            break;
          case 'DianaShelfMiddleware':
            pipeline.addMiddleware(
              DianaHandlerFactory.createShelfMiddleware(
                (component as ShelfMiddlewareComponent).dianaShelfMiddleware,
              ),
            );
            break;
        }
      }

      if (route.isStaticFileServer) {
        router.all(
          route.path,
          pipeline.addHandler(
            DianaHandlerFactory.createStaticFileServer(route.staticOptions!),
          ),
        );
        print(
          'Static file server registered ${dianaConfig.prefix}${controllerComposer.path}${route.path}',
        );
        continue;
      }

      router.add(
        route.method.name.toLowerCase(),
        route.path,
        pipeline.addHandler(
          DianaHandlerFactory.createControllerHandler(
            route.action,
            route.params,
            outputContentType: dianaConfig.defaultOutputContentType,
          ),
        ),
      );
      print(
        'Route registered ${dianaConfig.prefix}${controllerComposer.path}${route.path}',
      );
    }

    globalRouter.mount(
      dianaConfig.prefix + controllerComposer.path,
      router.call,
    );
  }

  Future<void> runServer(host, port) async {
    final server = await io.serve(
      globalPipeline.addHandler(globalRouter.call),
      host ?? 'localhost',
      port ?? 8080,
      securityContext: dianaConfig.securityContext,
    );
    server.autoCompress = true;
  }

  /// Middleware to redirect HTTP requests to HTTPS
  Middleware get _httpToHttpsRedirectMiddleware {
    return (Handler handler) {
      return (Request request) async {
        if (!request.requestedUri.isScheme('https')) {
          final httpsUri = request.requestedUri.replace(scheme: 'https');
          return Response.found(httpsUri.toString());
        }
        return await handler(request);
      };
    };
  }

  /// Middleware to redirect URLs without trailing slash to URLs with trailing slash
  Middleware get _trailingSlashRedirectMiddleware {
    return (Handler handler) {
      return (Request request) async {
        final path = request.requestedUri.path;

        // Only redirect if:
        // 1. Path doesn't end with '/'
        // 2. Path doesn't contain a file extension (no '.' in the last segment)
        // 3. It's a GET request (avoid redirecting POST/PUT/DELETE requests)
        if (!path.endsWith('/') &&
            request.method == 'GET' &&
            !path.split('/').last.contains('.')) {
          final redirectUri = request.requestedUri.replace(path: '$path/');
          return Response.movedPermanently(redirectUri.toString());
        }

        return await handler(request);
      };
    };
  }
}
