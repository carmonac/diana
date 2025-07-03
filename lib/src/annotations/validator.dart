class Validator {
  final (bool, String) Function(dynamic value) validate;
  const Validator(this.validate);
}
