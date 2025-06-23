import '../../adapter/request.dart';
import '../../adapter/response.dart';

abstract class DianaInterceptor {
  Future<void> onRequest(DianaRequest request) async {}
  Future<void> onResponse(DianaResponse response) async {}
}
