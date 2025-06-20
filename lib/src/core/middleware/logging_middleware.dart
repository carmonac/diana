import 'middleware.dart';
import '../http/request.dart';
import '../http/response.dart';
import '../http/handler.dart';

class LoggingMiddleware extends DianaMiddleware {
  @override
  Future<DianaResponse> handle(DianaRequest request, DianaHandler next) async {
    final start = DateTime.now();

    print('${request.method} ${request.uri.path} - Started');

    try {
      final response = await next(request);
      final duration = DateTime.now().difference(start);

      print(
        '${request.method} ${request.uri.path} - ${response.statusCode} (${duration.inMilliseconds}ms)',
      );

      return response;
    } catch (error) {
      final duration = DateTime.now().difference(start);
      print(
        '${request.method} ${request.uri.path} - ERROR: $error (${duration.inMilliseconds}ms)',
      );
      rethrow;
    }
  }
}
