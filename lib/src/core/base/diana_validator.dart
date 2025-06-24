abstract class DianaValidator<T> {
  Future<(bool, String)> isValid(T value);
}
