import '../core/base/diana_validator.dart';

class PropKey {
  final String key;
  final List<DianaValidator>? validators;
  const PropKey(this.key, {this.validators});
}
