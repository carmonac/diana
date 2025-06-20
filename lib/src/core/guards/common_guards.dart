import '../http/request.dart';
import '../http/response.dart';
import 'guard.dart';

/// Authentication guard that verifies if a request has valid authentication
class AuthGuard extends DianaGuard {
  String _tokenHeaderName;
  String? _secretKey;
  bool Function(String token)? _customTokenValidator;

  AuthGuard({
    String tokenHeaderName = 'authorization',
    String? secretKey,
    bool Function(String token)? customTokenValidator,
  }) : _tokenHeaderName = tokenHeaderName,
       _secretKey = secretKey,
       _customTokenValidator = customTokenValidator;

  @override
  Future<GuardResult> canActivate(
    DianaRequest request, [
    Map<String, dynamic>? config,
  ]) async {
    // Apply configuration from annotation if provided
    if (config != null) {
      _tokenHeaderName = config['tokenHeaderName'] ?? _tokenHeaderName;
      _secretKey = config['secretKey'] ?? _secretKey;
      // Note: customTokenValidator can't be easily serialized in annotations
    }

    final token = _extractToken(request);

    if (token == null) {
      return GuardResult.unauthorized('Authentication token required');
    }

    final isValid = await _validateToken(token);
    if (!isValid) {
      return GuardResult.unauthorized('Invalid authentication token');
    }

    // Add user info to context if token is valid
    final userInfo = await _extractUserInfo(token);
    return GuardResult.allow(contextData: {'user': userInfo});
  }

  String? _extractToken(DianaRequest request) {
    final authHeader = request.header(_tokenHeaderName);
    if (authHeader == null) return null;

    // Handle "Bearer token" format
    if (authHeader.startsWith('Bearer ')) {
      return authHeader.substring(7);
    }

    return authHeader;
  }

  Future<bool> _validateToken(String token) async {
    if (_customTokenValidator != null) {
      return _customTokenValidator!(token);
    }

    // Simple validation example - in real implementation you'd validate JWT, etc.
    if (_secretKey != null) {
      return token.isNotEmpty && token.contains(_secretKey!);
    }

    return token.isNotEmpty;
  }

  Future<Map<String, Object?>> _extractUserInfo(String token) async {
    // In a real implementation, you'd decode JWT or query user database
    return {'id': 'user123', 'token': token, 'authenticated': true};
  }
}

/// Role-based authorization guard
class RoleGuard extends DianaGuard {
  List<String> _requiredRoles;
  String _userContextKey;

  RoleGuard({
    required List<String> requiredRoles,
    String userContextKey = 'user',
  }) : _requiredRoles = requiredRoles,
       _userContextKey = userContextKey;

  @override
  Future<GuardResult> canActivate(
    DianaRequest request, [
    Map<String, dynamic>? config,
  ]) async {
    // Apply configuration from annotation if provided
    if (config != null) {
      if (config['roles'] != null) {
        _requiredRoles = List<String>.from(config['roles']);
      }
      _userContextKey = config['userContextKey'] ?? _userContextKey;
    }

    final user = request.getContext<Map<String, Object?>>(_userContextKey);

    if (user == null) {
      return GuardResult.unauthorized(
        'User information not found. Did you forget to add AuthGuard?',
      );
    }

    final userRoles = _extractUserRoles(user);
    final hasRequiredRole = _requiredRoles.any(userRoles.contains);

    if (!hasRequiredRole) {
      return GuardResult.forbidden(
        'Access denied. Required roles: ${_requiredRoles.join(', ')}',
      );
    }

    return GuardResult.allow();
  }

  List<String> _extractUserRoles(Map<String, Object?> user) {
    final roles = user['roles'];
    if (roles is List<String>) {
      return roles;
    } else if (roles is String) {
      return [roles];
    }
    return [];
  }
}

/// Rate limiting guard
class RateLimitGuard extends DianaGuard {
  final int _maxRequests;
  final Duration _timeWindow;
  final Map<String, List<DateTime>> _requestHistory = {};

  RateLimitGuard({required int maxRequests, required Duration timeWindow})
    : _maxRequests = maxRequests,
      _timeWindow = timeWindow;

  @override
  Future<GuardResult> canActivate(
    DianaRequest request, [
    Map<String, dynamic>? config,
  ]) async {
    final clientId = _getClientIdentifier(request);
    final now = DateTime.now();

    // Clean old requests
    _cleanOldRequests(clientId, now);

    final recentRequests = _requestHistory[clientId] ?? [];

    if (recentRequests.length >= _maxRequests) {
      return GuardResult.deny(
        DianaResponse(429, body: 'Rate limit exceeded. Try again later.'),
      );
    }

    // Record this request
    _requestHistory[clientId] = [...recentRequests, now];

    return GuardResult.allow();
  }

  String _getClientIdentifier(DianaRequest request) {
    // Use IP address as client identifier
    // In a real implementation, you might want to use user ID if authenticated
    return request.header('x-forwarded-for') ??
        request.header('x-real-ip') ??
        'unknown';
  }

  void _cleanOldRequests(String clientId, DateTime now) {
    final requests = _requestHistory[clientId];
    if (requests == null) return;

    final cutoff = now.subtract(_timeWindow);
    _requestHistory[clientId] = requests
        .where((requestTime) => requestTime.isAfter(cutoff))
        .toList();
  }
}
