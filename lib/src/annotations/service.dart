// enum for service scope
enum ServiceScope {
  /// A singleton service scope, meaning only one instance of the service will be created.
  singleton,

  /// A transient service scope, meaning a new instance of the service will be created
  /// each time it is requested.
  transient,

  /// A scoped service scope, meaning a new instance of the service will be created
  /// for each scope, such as per request in a web application.
  scoped,
}

/// This is a service annotation for marking classes as services in dependency injection.
/// It is used to indicate that a class should be treated as a service in the
/// dependency injection framework, allowing it to be registered and resolved
/// as a service. It has a default scope of singleton, meaning that only one instance
/// of the service will be created and reused throughout the application. But also can be set
/// to transient or scoped if needed.
/// Example usage:
/// ```dart
/// @Service()
/// class MyService {
///   ...Service implementation
/// }
/// ```
class Service {
  /// The scope of the service, defaulting to singleton.
  final ServiceScope scope;

  /// Creates a new instance of [Service] with the specified [scope].
  /// If no scope is provided, it defaults to 'singleton'.
  const Service({this.scope = ServiceScope.singleton});
}
