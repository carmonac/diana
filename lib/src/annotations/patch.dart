/// This is the patch annotation for marking methods as patch handlers in a web application.
/// It is used to indicate that a method should handle HTTP PATCH requests.
/// Example usage:
/// ```dart
/// @Patch('/update')
/// void updateData() {
///
/// }
/// The [path] parameter specifies the URL path that this patch handler will respond to.
/// If no path is provided, it defaults to '/'.
class Patch {
  /// The path for the patch handler, defaulting to '/'.
  final String path;
  Patch([this.path = '/']);

  /// Returns a hash code for the patch annotation.
  @override
  int get hashCode {
    return runtimeType.hashCode ^ path.hashCode;
  }

  /// Checks if this patch annotation is equal to another object.
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Patch && other.path == path;
  }
}
