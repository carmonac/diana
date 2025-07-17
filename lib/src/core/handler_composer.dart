import 'package:diana/src/core/version.dart';

import '../http/http_method.dart';
import 'parameter_type.dart';
import 'base/base.dart';
import 'static_options.dart';

sealed class HandlerComponent {
  Type get type;
}

class InterceptorComponent extends HandlerComponent {
  final AbstractInterceptor interceptor;

  InterceptorComponent(this.interceptor);

  @override
  Type get type => AbstractInterceptor;
}

class GuardComponent extends HandlerComponent {
  final AbstractGuard guard;

  GuardComponent(this.guard);

  @override
  Type get type => AbstractGuard;
}

class MiddlewareComponent extends HandlerComponent {
  final AbstractMiddleware middleware;

  MiddlewareComponent(this.middleware);

  @override
  Type get type => AbstractMiddleware;
}

class ShelfMiddlewareComponent extends HandlerComponent {
  final AbstractShelfMiddleware dianaShelfMiddleware;

  ShelfMiddlewareComponent(this.dianaShelfMiddleware);

  @override
  Type get type => AbstractShelfMiddleware;
}

class ControllerComposer {
  final String path;
  final List<HandlerComponent> _components = [];
  final List<ControllerRouteComposer> _routes = [];
  final Version? version;
  final String? description;

  ControllerComposer(this.path, this.version, this.description);

  void addComponent(HandlerComponent componentObject) {
    _components.add(componentObject);
  }

  void addRoute(ControllerRouteComposer route) {
    _routes.add(route);
  }

  List<HandlerComponent> get components => _components;
  List<ControllerRouteComposer> get routes => _routes;
}

class Parameter {
  final String? name;
  final Type? typeOf;
  final ParameterType type;
  final List<AbstractValidator>? validators;
  final List<AbstractTransformer>? transformers;

  Parameter({
    this.name,
    this.type = ParameterType.query,
    this.typeOf,
    this.validators,
    this.transformers,
  });
}

class ControllerRouteComposer<T extends Function> {
  final String path;
  final HttpMethod method;
  final T action;
  final bool isStaticFileServer;
  final Version? version;
  final String? description;

  /// If true, this route will serve static files.
  final StaticOptions? staticOptions;

  final List<HandlerComponent> _components = [];
  final List<Parameter> params;

  ControllerRouteComposer({
    required this.path,
    required this.method,
    required this.action,
    this.params = const [],
    this.isStaticFileServer = false,
    this.staticOptions,
    this.version,
    this.description,
  });

  void addComponent(HandlerComponent componentObject) {
    _components.add(componentObject);
  }

  List<HandlerComponent> get components => _components;
  List<dynamic> get routeParams => params;
}

class GlobalComposer {
  final List<HandlerComponent> _components = [];

  void addComponent(HandlerComponent componentObject) {
    _components.add(componentObject);
  }

  List<HandlerComponent> get components => _components;
}
