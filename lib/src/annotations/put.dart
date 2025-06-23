/// This is the put annotation for marking methods as put handlers in a web application.
/// It is used to indicate that a method should handle HTTP POST requests.
/// Example usage:
/// ```dart
/// @Put('/insert')
/// void insertOrReplaceData() {
///
/// }
/// The [path] parameter specifies the URL path that this put handler will respond to.
/// If no path is provided, it defaults to '/'.
class Put {
  /// The path for the put handler, defaulting to '/'.
  final String path;
  const Put([this.path = '/']);

  /// Returns a hash code for the put annotation.
  @override
  int get hashCode {
    return runtimeType.hashCode ^ path.hashCode;
  }

  /// Checks if this put annotation is equal to another object.
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Put && other.path == path;
  }
}
