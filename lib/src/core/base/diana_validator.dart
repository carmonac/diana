import 'dart:async';

abstract class DianaValidator<T> {
  FutureOr<(bool, String)> isValid(T value);
}
