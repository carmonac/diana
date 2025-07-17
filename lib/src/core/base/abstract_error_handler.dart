import '../../http/interfaces.dart';

abstract class AbstractErrorHandler {
  /// Handles errors that occur during the request processing.
  ///
  /// This method is called when an error is thrown in the request processing pipeline.
  /// It allows for custom error handling logic, such as logging or transforming the error.
  ///
  /// Returns a [DianaResponse] that represents the error response to be sent to the client.
  Future<DianaResponse> handle(
    Object error,
    StackTrace stackTrace,
    DianaRequest request,
  );
}
