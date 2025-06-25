import 'http_method.dart';
import 'parameter_type.dart';
import 'base/base.dart';

sealed class HandlerComponent {
  Type get type;
}

class InterceptorComponent extends HandlerComponent {
  final DianaInterceptor interceptor;

  InterceptorComponent(this.interceptor);

  @override
  Type get type => DianaInterceptor;
}

class GuardComponent extends HandlerComponent {
  final DianaGuard guard;

  GuardComponent(this.guard);

  @override
  Type get type => DianaGuard;
}

class MiddlewareComponent extends HandlerComponent {
  final DianaMiddleware middleware;

  MiddlewareComponent(this.middleware);

  @override
  Type get type => DianaMiddleware;
}

class ShelfMiddlewareComponent extends HandlerComponent {
  final DianaShelfMiddleware dianaShelfMiddleware;

  ShelfMiddlewareComponent(this.dianaShelfMiddleware);

  @override
  Type get type => DianaShelfMiddleware;
}

class ControllerComposer {
  final String path;
  final List<HandlerComponent> _components = [];
  final List<ControllerRouteComposer> _routes = [];

  ControllerComposer(this.path);

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

  Parameter({this.name, this.type = ParameterType.query, this.typeOf});
}

class ControllerRouteComposer<T extends Function> {
  final String path;
  final HttpMethod method;
  final T action;

  final List<HandlerComponent> _components = [];
  final List<Parameter> params;

  ControllerRouteComposer({
    required this.path,
    required this.method,
    required this.action,
    this.params = const [],
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
