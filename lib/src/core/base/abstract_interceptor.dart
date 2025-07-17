import '../../http/interfaces.dart';

abstract class AbstractInterceptor {
  Future<void> onRequest(DianaRequest request) async {}
  Future<void> onResponse(DianaResponse response) async {}
}
