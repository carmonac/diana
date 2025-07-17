import 'dart:async';

import '../core/diana_config.dart';
import '../core/handler_composer.dart';
import '../core/utils.dart';
import '../http/interfaces.dart';
import '../core/diana_handler_factory.dart';
import 'shelf/shelf_response_factory.dart';
import 'shelf/shelf_static_file_server_factory.dart';
import '../core/response_factory_registry.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'shelf/shelf_error_response.dart';
import '../core/secure_cookie_handler.dart';
import '../core/secure_session_handler.dart';

class Adapter {
  final globalRouter = Router();
  final globalPipeline = Pipeline();
  final DianaConfig dianaConfig;
  final DianaResponseFactory responseFactory;
  final DianaStaticFileServerFactory staticFileServerFactory;

  Adapter({
    GlobalComposer? globalComposer,
    List<ControllerComposer> controllers = const [],
    DianaConfig? dianaConfig,
    DianaResponseFactory? responseFactory,
    DianaStaticFileServerFactory? staticFileServerFactory,
  }) : dianaConfig = dianaConfig ?? DianaConfig(),
       responseFactory = responseFactory ?? ShelfResponseFactory(),
       staticFileServerFactory =
           staticFileServerFactory ?? ShelfStaticFileServerFactory() {
    // Configure the global response factory registry
    ResponseFactoryRegistry.setFactory(this.responseFactory);
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
        ShelfErrorResponse.customErrorResponse(dianaConfig.errorHandler!),
      );
    } else {
      globalPipeline.addMiddleware(
        ShelfErrorResponse.dianaErrorResponse(
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
        case 'AbstractGuard':
          globalPipeline.addMiddleware(
            DianaHandlerFactory.createGuard(
              (component as GuardComponent).guard,
            ),
          );
          break;
        case 'AbstractMiddleware':
          globalPipeline.addMiddleware(
            DianaHandlerFactory.createMiddleware(
              (component as MiddlewareComponent).middleware,
            ),
          );
          break;
        case 'AbstractInterceptor':
          globalPipeline.addMiddleware(
            DianaHandlerFactory.createInterceptor(
              (component as InterceptorComponent).interceptor,
            ),
          );
          break;
        case 'AbstractShelfMiddleware':
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
        case 'AbstractGuard':
          pipeline.addMiddleware(
            DianaHandlerFactory.createGuard(
              (component as GuardComponent).guard,
            ),
          );
          break;
        case 'AbstractMiddleware':
          pipeline.addMiddleware(
            DianaHandlerFactory.createMiddleware(
              (component as MiddlewareComponent).middleware,
            ),
          );
          break;
        case 'AbstractInterceptor':
          pipeline.addMiddleware(
            DianaHandlerFactory.createInterceptor(
              (component as InterceptorComponent).interceptor,
            ),
          );
          break;
        case 'AbstractShelfMiddleware':
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
          case 'AbstractGuard':
            pipeline.addMiddleware(
              DianaHandlerFactory.createGuard(
                (component as GuardComponent).guard,
              ),
            );
            break;
          case 'AbstractMiddleware':
            pipeline.addMiddleware(
              DianaHandlerFactory.createMiddleware(
                (component as MiddlewareComponent).middleware,
              ),
            );
            break;
          case 'AbstractInterceptor':
            pipeline.addMiddleware(
              DianaHandlerFactory.createInterceptor(
                (component as InterceptorComponent).interceptor,
              ),
            );
            break;
          case 'AbstractShelfMiddleware':
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
            DianaHandlerFactory.createStaticFileServer(
              route.staticOptions!,
              staticFileServerFactory,
            ),
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
            responseFactory: responseFactory,
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
