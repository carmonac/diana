import '../core/handler_composer.dart';
import '../core/utils.dart';
import 'diana_handler_factory.dart';
import 'request.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

class Adapter {
  final globalRouter = Router();
  final globalPipeline = Pipeline();
  final String prefix;

  Adapter({this.prefix = ''});

  void setUpGlobalPipeline([GlobalComposer? globalComposer]) {
    if (globalComposer == null) {
      return;
    }
    globalPipeline.addMiddleware((Handler nextHandler) {
      return (Request request) async {
        final dianaRequest = DianaRequest.fromShelf(request);
        final modifiedRequest = dianaRequest.copyWith(
          context: {'requestId': generateRequestId()},
        );
        return await nextHandler(modifiedRequest.shelfRequest);
      };
    });
    for (final component in globalComposer.components) {
      switch (component.type) {
        case HandlerType.guard:
          globalPipeline.addMiddleware(
            DianaHandlerFactory.createGuard(
              (component as GuardComponent).guard,
            ),
          );
          break;
        case HandlerType.middleware:
          globalPipeline.addMiddleware(
            DianaHandlerFactory.createMiddleware(
              (component as MiddlewareComponent).middleware,
            ),
          );
          break;
        case HandlerType.interceptor:
          globalPipeline.addMiddleware(
            DianaHandlerFactory.createInterceptor(
              (component as InterceptorComponent).interceptor,
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
      switch (component.type) {
        case HandlerType.guard:
          pipeline.addMiddleware(
            DianaHandlerFactory.createGuard(
              (component as GuardComponent).guard,
            ),
          );
          break;
        case HandlerType.middleware:
          pipeline.addMiddleware(
            DianaHandlerFactory.createMiddleware(
              (component as MiddlewareComponent).middleware,
            ),
          );
          break;
        case HandlerType.interceptor:
          pipeline.addMiddleware(
            DianaHandlerFactory.createInterceptor(
              (component as InterceptorComponent).interceptor,
            ),
          );
          break;
      }
    }
    for (final route in controllerComposer.routes) {
      for (final component in route.components) {
        switch (component.type) {
          case HandlerType.guard:
            pipeline.addMiddleware(
              DianaHandlerFactory.createGuard(
                (component as GuardComponent).guard,
              ),
            );
            break;
          case HandlerType.middleware:
            pipeline.addMiddleware(
              DianaHandlerFactory.createMiddleware(
                (component as MiddlewareComponent).middleware,
              ),
            );
            break;
          case HandlerType.interceptor:
            pipeline.addMiddleware(
              DianaHandlerFactory.createInterceptor(
                (component as InterceptorComponent).interceptor,
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
