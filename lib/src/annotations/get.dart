/// This is the get annotation for marking methods as get handlers in a web application.
/// It is used to indicate that a method should handle HTTP GET requests.
/// Example usage:
/// ```dart
/// @Get('/<id>')
/// void getData() {
///
/// }
/// /// The [path] parameter specifies the URL path that this post handler will respond to.
/// If no path is provided, it defaults to '/'.
class Get {
  /// The path for the get handler, defaulting to '/'.
  final String path;
  const Get([this.path = '/']);

  /// Returns a hash code for the post annotation.
  @override
  int get hashCode {
    return runtimeType.hashCode ^ path.hashCode;
  }

  /// Checks if this get annotation is equal to another object.
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Get && other.path == path;
  }
}
