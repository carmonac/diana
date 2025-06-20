import '../http/handler.dart';
import '../http/request.dart';
import '../http/response.dart';
import '../middleware/middleware.dart';
import 'guard.dart';
import 'common_guards.dart';

// Export guards for convenience
export 'guard.dart';
export 'common_guards.dart';

/// Middleware that executes guards before allowing request to continue
class GuardMiddleware extends DianaMiddleware {
  final List<DianaGuard> _guards;

  GuardMiddleware(this._guards);

  /// Create middleware with a single guard
  GuardMiddleware.single(DianaGuard guard) : _guards = [guard];

  @override
  Future<DianaResponse> handle(DianaRequest request, DianaHandler next) async {
    // Execute all guards
    final result = await _executeGuards(request);

    if (!result.canActivate) {
      // Return the guard's response if access is denied
      return result.response!;
    }

    // Update request context with guard data and continue
    final updatedRequest = result.contextData != null
        ? request.copyWith(context: result.contextData)
        : request;

    return await next(updatedRequest);
  }

  Future<GuardResult> _executeGuards(DianaRequest request) async {
    var currentRequest = request;
    final allContextData = <String, Object?>{};

    for (final guard in _guards) {
      final result = await guard.canActivate(currentRequest);

      if (!result.canActivate) {
        return result;
      }

      // Merge context data from successful guards
      if (result.contextData != null) {
        allContextData.addAll(result.contextData!);
        currentRequest = currentRequest.copyWith(context: allContextData);
      }
    }

    return GuardResult.allow(contextData: allContextData);
  }
}

/// Utility functions for creating guard middleware
class Guards {
  /// Create middleware that applies authentication guard
  static GuardMiddleware auth({
    String tokenHeaderName = 'authorization',
    String? secretKey,
    bool Function(String token)? customTokenValidator,
  }) {
    return GuardMiddleware.single(
      AuthGuard(
        tokenHeaderName: tokenHeaderName,
        secretKey: secretKey,
        customTokenValidator: customTokenValidator,
      ),
    );
  }

  /// Create middleware that applies role-based authorization
  static GuardMiddleware roles(
    List<String> requiredRoles, {
    String userContextKey = 'user',
  }) {
    return GuardMiddleware.single(
      RoleGuard(requiredRoles: requiredRoles, userContextKey: userContextKey),
    );
  }

  /// Create middleware that applies rate limiting
  static GuardMiddleware rateLimit({
    required int maxRequests,
    required Duration timeWindow,
  }) {
    return GuardMiddleware.single(
      RateLimitGuard(maxRequests: maxRequests, timeWindow: timeWindow),
    );
  }

  /// Create middleware that combines multiple guards
  static GuardMiddleware combine(List<DianaGuard> guards) {
    return GuardMiddleware(guards);
  }

  /// Create middleware with auth + roles (common pattern)
  static GuardMiddleware authAndRoles(
    List<String> requiredRoles, {
    String tokenHeaderName = 'authorization',
    String? secretKey,
    bool Function(String token)? customTokenValidator,
    String userContextKey = 'user',
  }) {
    return GuardMiddleware([
      AuthGuard(
        tokenHeaderName: tokenHeaderName,
        secretKey: secretKey,
        customTokenValidator: customTokenValidator,
      ),
      RoleGuard(requiredRoles: requiredRoles, userContextKey: userContextKey),
    ]);
  }
}
