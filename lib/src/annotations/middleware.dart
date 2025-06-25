abstract class BaseMiddleware {
  final Type middleware;
  final Map<String, dynamic> options;
  const BaseMiddleware(this.middleware, {this.options = const {}});
}

class Middleware extends BaseMiddleware {
  const Middleware(super.middleware, {super.options = const {}});
}

class GlobalMiddleware extends BaseMiddleware {
  const GlobalMiddleware(super.middleware, {super.options = const {}});
}
