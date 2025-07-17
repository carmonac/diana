abstract class BaseMiddlewareAnnotation {
  final Type middleware;
  final Map<String, dynamic> options;
  const BaseMiddlewareAnnotation(this.middleware, {this.options = const {}});
}

class Middleware extends BaseMiddlewareAnnotation {
  const Middleware(super.middleware, {super.options = const {}});
}

class GlobalMiddleware extends BaseMiddlewareAnnotation {
  const GlobalMiddleware(super.middleware, {super.options = const {}});
}
