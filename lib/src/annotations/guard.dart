import '../core/base/base.dart';

abstract class BaseGuard {
  final DianaGuard guard;
  const BaseGuard(this.guard);
}

class Guard extends BaseGuard {
  const Guard(super.guard);
}

class GlobalGuard extends BaseGuard {
  const GlobalGuard(super.guard);
}
