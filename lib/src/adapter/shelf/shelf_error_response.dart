import 'package:diana/src/core/base/abstract_error_handler.dart';
import 'package:shelf/shelf.dart';
import 'package:diana/src/core/base/base.dart';
import 'package:diana/src/core/exceptions/exceptions.dart';
import 'package:diana/src/http/interfaces.dart';
import '../../core/error_response.dart';
import 'shelf_request_adapter.dart';
import 'shelf_response_adapter.dart';

/// Shelf-specific error response adapter
/// Wraps framework-agnostic error responses for use with Shelf
class ShelfErrorResponse {
  /// Creates a Shelf middleware that uses Diana's error response system
  static Middleware dianaErrorResponse(
    String outputContentType, [
    DianaHttpErrorBuilder? errorBuilder,
  ]) {
    // Get the framework-agnostic error middleware
    final dianaErrorMiddleware = ErrorResponse.dianaErrorResponse(
      outputContentType,
      errorBuilder,
    );

    // Wrap it for Shelf compatibility
    return (Handler innerHandler) {
      return (Request request) async {
        // Convert Shelf request to Diana request
        final dianaRequest = ShelfRequestAdapter(request);

        // Create Diana handler that converts back to Shelf
        DianaHandler dianaHandler = (DianaRequest req) async {
          final shelfResponse = await innerHandler(request);
          return ShelfResponseAdapter.fromShelf(shelfResponse);
        };

        // Apply Diana error middleware
        final errorAwareHandler = dianaErrorMiddleware(dianaHandler);

        // Execute and convert response back to Shelf
        final dianaResponse = await errorAwareHandler(dianaRequest);
        return (dianaResponse as ShelfResponseAdapter).shelfResponse;
      };
    };
  }

  /// Creates a Shelf middleware for custom error handling
  static Middleware customErrorResponse(AbstractErrorHandler errorHandler) {
    // Get the framework-agnostic error middleware
    final dianaErrorMiddleware = ErrorResponse.customErrorResponse(
      errorHandler,
    );

    // Wrap it for Shelf compatibility
    return (Handler innerHandler) {
      return (Request request) async {
        // Convert Shelf request to Diana request
        final dianaRequest = ShelfRequestAdapter(request);

        // Create Diana handler that converts back to Shelf
        dianaHandler(DianaRequest req) async {
          final shelfResponse = await innerHandler(request);
          return ShelfResponseAdapter.fromShelf(shelfResponse);
        }

        // Apply Diana error middleware
        final errorAwareHandler = dianaErrorMiddleware(dianaHandler);

        // Execute and convert response back to Shelf
        final dianaResponse = await errorAwareHandler(dianaRequest);
        return (dianaResponse as ShelfResponseAdapter).shelfResponse;
      };
    };
  }
}
