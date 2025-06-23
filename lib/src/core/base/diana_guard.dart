import '../../adapter/request.dart';

abstract class DianaGuard {
  Future<bool> canActivate(DianaRequest request);
}
