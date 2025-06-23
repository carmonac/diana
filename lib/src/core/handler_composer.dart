import 'package:diana/src/core/http_method.dart';

import 'base/base.dart';

enum HandlerType { guard, middleware, interceptor }

sealed class HandlerComponent {
  HandlerType get type;
}

class InterceptorComponent extends HandlerComponent {
  final DianaInterceptor interceptor;

  InterceptorComponent(this.interceptor);

  @override
  HandlerType get type => HandlerType.interceptor;
}

class GuardComponent extends HandlerComponent {
  final DianaGuard guard;

  GuardComponent(this.guard);

  @override
  HandlerType get type => HandlerType.guard;
}

class MiddlewareComponent extends HandlerComponent {
  final DianaMiddleware middleware;

  MiddlewareComponent(this.middleware);

  @override
  HandlerType get type => HandlerType.middleware;
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

enum ParameterType {
  path,
  query,
  queryList,
  body,
  header,
  cookie,
  formData,
  file,
  session,
  request,
  custom,
  ip,
  host,
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
