import 'package:diana/src/core/http_method.dart';

enum HandlerType { guard, middleware, interceptor }

class HandlerComponent {
  final HandlerType type;

  final Function handler;

  HandlerComponent(this.type, this.handler);
}

class ControllerComposer {
  final String path;
  final List<HandlerComponent> _components = [];
  final List<ControllerRouteComposer> _routes = [];

  ControllerComposer(this.path);

  void addComponent(HandlerType type, Function handler) {
    _components.add(HandlerComponent(type, handler));
  }

  void addRoute(ControllerRouteComposer route) {
    _routes.add(route);
  }

  List<HandlerComponent> get components => _components;
  List<ControllerRouteComposer> get routes => _routes;
}

enum parameterType {
  path,
  query,
  body,
  header,
  cookie,
  formData,
  file,
  session,
  custom,
}

class Parameter {
  final String? name;
  final Type? typeOf;
  final parameterType type;

  Parameter({this.name, this.type = parameterType.query, this.typeOf});
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

  void addComponent(HandlerType type, Function handler) {
    _components.add(HandlerComponent(type, handler));
  }

  List<HandlerComponent> get components => _components;
  List<dynamic> get routeParams => params;
}

class GlobalComposer {
  final List<HandlerComponent> _components = [];

  void addComponent(HandlerType type, Function handler) {
    _components.add(HandlerComponent(type, handler));
  }

  List<HandlerComponent> get components => _components;
}
