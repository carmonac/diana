abstract class BaseInterceptor {
  final Type interceptor;
  final Map<String, dynamic> options;
  const BaseInterceptor(this.interceptor, {this.options = const {}});
}

class Interceptor extends BaseInterceptor {
  const Interceptor(super.interceptor, {super.options = const {}});
}

class GlobalInterceptor extends BaseInterceptor {
  const GlobalInterceptor(super.interceptor, {super.options = const {}});
}
