import 'dart:async';

import '../../adapter/request.dart';

abstract class DianaGuard {
  FutureOr<bool> canActivate(DianaRequest request);
}
