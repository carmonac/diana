import 'dart:async';

abstract class AbstractValidator<T> {
  FutureOr<(bool, String)> isValid(T value);
}
