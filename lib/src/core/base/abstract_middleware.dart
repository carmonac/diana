import '../../http/interfaces.dart';

abstract class AbstractMiddleware {
  Future<DianaResponse> use(DianaRequest request, DianaHandler next);
}
