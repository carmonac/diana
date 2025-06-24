import '../core/base/base.dart';

abstract class BaseInterceptor {
  final DianaInterceptor interceptor;
  const BaseInterceptor(this.interceptor);
}

class Interceptor extends BaseInterceptor {
  const Interceptor(super.interceptor);
}

class GlobalInterceptor extends BaseInterceptor {
  const GlobalInterceptor(super.interceptor);
}
