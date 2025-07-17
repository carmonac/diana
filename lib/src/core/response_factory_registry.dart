import '../http/interfaces.dart';
import '../adapter/shelf/shelf_response_factory.dart';

/// Global registry for HTTP response factory
/// This allows response classes to access the configured factory without manual injection
class ResponseFactoryRegistry {
  static DianaResponseFactory _factory = ShelfResponseFactory();

  /// Gets the current response factory
  static DianaResponseFactory get factory => _factory;

  /// Sets the response factory
  /// This should be called during application initialization
  static void setFactory(DianaResponseFactory factory) {
    _factory = factory;
  }

  /// Resets to default factory (mainly for testing)
  static void reset() {
    _factory = ShelfResponseFactory();
  }
}
