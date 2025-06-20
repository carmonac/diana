/// This is the post annotation for marking methods as post handlers in a web application.
/// It is used to indicate that a method should handle HTTP POST requests.
/// Example usage:
/// ```dart
/// @Post('/submit')
/// void submitData() {
///
/// }
/// The [path] parameter specifies the URL path that this post handler will respond to.
/// If no path is provided, it defaults to '/'.
class Post {
  /// The path for the post handler, defaulting to '/'.
  final String path;
  Post([this.path = '/']);

  /// Returns a hash code for the post annotation.
  @override
  int get hashCode {
    return runtimeType.hashCode ^ path.hashCode;
  }

  /// Checks if this post annotation is equal to another object.
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Post && other.path == path;
  }
}
