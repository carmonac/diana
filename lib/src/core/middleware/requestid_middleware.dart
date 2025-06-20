import 'package:uuid/uuid.dart';
import '../http/request.dart';
import '../http/response.dart';
import '../http/handler.dart';
import 'middleware.dart';

/// Middleware that adds a unique request ID to each request
class RequestIdMiddleware extends DianaMiddleware {
  final String _contextKey;
  final Uuid _uuid;

  RequestIdMiddleware({String contextKey = 'request_id'})
    : _contextKey = contextKey,
      _uuid = const Uuid();

  @override
  Future<DianaResponse> handle(DianaRequest request, DianaHandler next) async {
    final requestId = _uuid.v4();

    // Add request ID to context
    final requestWithId = request.copyWith(context: {_contextKey: requestId});

    // Continue with the modified request
    return await next(requestWithId);
  }
}
