import '../../adapter/handler.dart';
import '../../adapter/request.dart';
import '../../adapter/response.dart';

abstract class DianaMiddleware {
  Future<DianaResponse> use(DianaRequest request, DianaHandler next);
}
