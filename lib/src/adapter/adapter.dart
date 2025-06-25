import 'dart:async';

import '../core/handler_composer.dart';
import '../core/utils.dart';
import 'diana_handler_factory.dart';
import 'request.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'error_response.dart';

class Adapter {
  final globalRouter = Router();
  final globalPipeline = Pipeline();
  final String prefix;
  final Middleware? errorHandler;

  Adapter({this.prefix = '', this.errorHandler});

  void setUpGlobalPipeline([GlobalComposer? globalComposer]) {
    globalPipeline.addMiddleware((Handler nextHandler) {
      return (Request request) async {
        final dianaRequest = DianaRequest.fromShelf(request);
        final modifiedRequest = dianaRequest.copyWith(
          context: {'request_id': generateRequestId()},
        );
        return await nextHandler(modifiedRequest.shelfRequest);
      };
    });

    if (errorHandler != null) {
      globalPipeline.addMiddleware(errorHandler!);
    } else {
      globalPipeline.addMiddleware(ErrorResponse.dianaErrorResponse());
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

      router.add(
        route.method.name.toLowerCase(),
        route.path,
        pipeline.addHandler(
          DianaHandlerFactory.createOptimizedControllerHandler(
            route.action,
            route.params,
          ),
        ),
      );
      print('Route registered $prefix${controllerComposer.path}${route.path}');
    }

    globalRouter.mount(prefix + controllerComposer.path, router.call);
  }

  Future<void> runServer(host, port) async {
    final server = await io.serve(
      globalPipeline.addHandler(globalRouter.call),
      host ?? 'localhost',
      port ?? 8080,
    );
    server.autoCompress = true;
  }
}
