import 'dart:async';

import '../../http/interfaces.dart';

abstract class AbstractGuard {
  FutureOr<bool> canActivate(DianaRequest request);
}
