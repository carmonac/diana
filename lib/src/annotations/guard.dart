abstract class BaseGuard {
  final Type guard;
  final Map<String, dynamic> options;
  const BaseGuard(this.guard, {this.options = const {}});
}

class Guard extends BaseGuard {
  const Guard(super.guard, {super.options = const {}});
}

class GlobalGuard extends BaseGuard {
  const GlobalGuard(super.guard, {super.options = const {}});
}
