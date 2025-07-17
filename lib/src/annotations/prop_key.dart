import '../core/base/abstract_validator.dart';

class PropKey {
  final String key;
  final List<AbstractValidator>? validators;
  const PropKey(this.key, {this.validators});
}
