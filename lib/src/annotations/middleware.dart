import '../core/base/base.dart';

abstract class BaseMiddleware {
  final DianaMiddleware middleware;
  const BaseMiddleware(this.middleware);
}

class Middleware extends BaseMiddleware {
  const Middleware(super.middleware);
}

class GlobalMiddleware extends BaseMiddleware {
  const GlobalMiddleware(super.middleware);
}
