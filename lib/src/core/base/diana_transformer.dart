abstract class DianaTransformer<T, R> {
  /// Transforms a value of type [T] to a value of type [R].
  ///
  /// Returns the transformed value.
  Future<R> transform(T value);
}
