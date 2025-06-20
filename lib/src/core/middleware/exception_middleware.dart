import 'package:shelf/shelf.dart';
import '../exceptions.dart';

Middleware httpExceptionHandler() {
  return (Handler handler) {
    return (Request request) async {
      try {
        return await handler(request);
      } on HttpException catch (e) {
        return Response(
          e.statusCode,
          body: _formatBody(e),
          headers: _getHeaders(request),
        );
      } catch (e, s) {
        // Manejo de errores no controlados
        return Response.internalServerError(
          body: _formatError(e, s),
          headers: _getHeaders(request),
        );
      }
    };
  };
}

String _formatBody(HttpException e) {
  return e.toJson().toString(); // TODO: Convert to JSON string if needed
}

String _formatError(Object error, StackTrace stackTrace) {
  return 'Unhandled Error: ${error.toString()}\n${stackTrace.toString()}';
}

Map<String, String> _getHeaders(Request request) {
  return {
    'Content-Type': 'application/json',
    'X-Request-ID': request.context['request_id']?.toString() ?? '',
  };
}
