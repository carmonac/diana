/// this is the controller annotation
/// It is used to mark classes as controllers.
/// Controllers are typically used in the context of MVC (Model-View-Controller)
/// or similar architectures, where they handle user input, manage application state,
/// and coordinate between the model and view layers.
/// Example usage:
/// ```dart
/// @Controller()
/// class MyController {
///   ...Controller implementation
/// }
/// ```
class Controller {
  /// Creates a new instance of [Controller].
  /// The [path] parameter specifies the URL path that this controller will respond to.
  /// If no path is provided, it defaults to '/'.
  final String path;
  Controller([this.path = '/']);

  /// Returns a hash code for the controller annotation.
  @override
  int get hashCode {
    return runtimeType.hashCode;
  }

  /// Checks if this controller annotation is equal to another object.
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Controller;
  }
}
