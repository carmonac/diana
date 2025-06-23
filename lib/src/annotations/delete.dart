/// This is the delete annotation for marking methods as delete handlers in a web application.
/// It is used to indicate that a method should handle HTTP POST requests.
/// Example usage:
/// ```dart
/// @Delete('/delete')
/// void delete() {
///
/// }
/// The [path] parameter specifies the URL path that this delete handler will respond to.
/// If no path is provided, it defaults to '/'.
class Delete {
  /// The path for the delete handler, defaulting to '/'.
  final String path;
  const Delete([this.path = '/']);

  /// Returns a hash code for the delete annotation.
  @override
  int get hashCode {
    return runtimeType.hashCode ^ path.hashCode;
  }

  /// Checks if this delete annotation is equal to another object.
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Delete && other.path == path;
  }
}
