import '../lib/diana.dart';

/// Example showing how to use guards in Diana framework
void main() async {
  // Note: This example assumes Diana class exists with middleware support
  // You would need to implement the Diana class with route handling

  // Example 1: Simple authentication guard
  print('Example 1: Authentication Guard');
  final authMiddleware = Guards.auth(secretKey: 'my-secret-key');
  print('Auth middleware created: ${authMiddleware.runtimeType}');

  // Example 2: Role-based authorization
  print('\nExample 2: Role-based Authorization');
  final roleMiddleware = Guards.authAndRoles(['admin']);
  print('Role middleware created: ${roleMiddleware.runtimeType}');

  // Example 3: Rate limiting
  print('\nExample 3: Rate Limiting');
  final rateLimitMiddleware = Guards.rateLimit(
    maxRequests: 10,
    timeWindow: Duration(minutes: 1),
  );
  print('Rate limit middleware created: ${rateLimitMiddleware.runtimeType}');

  // Example 4: Combining multiple guards
  print('\nExample 4: Combined Guards');
  final combinedMiddleware = Guards.combine([
    AuthGuard(secretKey: 'my-secret-key'),
    RoleGuard(requiredRoles: ['admin']),
    RateLimitGuard(maxRequests: 5, timeWindow: Duration(minutes: 1)),
  ]);
  print('Combined middleware created: ${combinedMiddleware.runtimeType}');

  // Example 5: Custom guards
  print('\nExample 5: Custom Guards');
  final ipGuard = IPWhitelistGuard(['192.168.1.100', '10.0.0.1']);
  final timeGuard = TimeBasedGuard(startHour: 9, endHour: 17);

  print('IP whitelist guard created: ${ipGuard.runtimeType}');
  print('Time-based guard created: ${timeGuard.runtimeType}');
}

/// Example of creating a custom guard
class IPWhitelistGuard extends DianaGuard {
  final List<String> _allowedIPs;

  IPWhitelistGuard(this._allowedIPs);

  @override
  Future<GuardResult> canActivate(DianaRequest request) async {
    final clientIP =
        request.header('x-forwarded-for') ??
        request.header('x-real-ip') ??
        'unknown';

    if (!_allowedIPs.contains(clientIP)) {
      return GuardResult.forbidden('IP address not allowed: $clientIP');
    }

    return GuardResult.allow(contextData: {'clientIP': clientIP});
  }
}

/// Example usage of custom guard
void customGuardExample() {
  // Example of how you would use custom guards in routes
  print('\nCustom Guard Example:');
  final ipMiddleware = GuardMiddleware.single(
    IPWhitelistGuard(['192.168.1.100', '10.0.0.1']),
  );
  print('IP whitelist middleware created: ${ipMiddleware.runtimeType}');
}

/// Example of time-based access guard
class TimeBasedGuard extends DianaGuard {
  final int _startHour;
  final int _endHour;

  TimeBasedGuard({required int startHour, required int endHour})
    : _startHour = startHour,
      _endHour = endHour;

  @override
  Future<GuardResult> canActivate(DianaRequest request) async {
    final now = DateTime.now();
    final currentHour = now.hour;

    if (currentHour < _startHour || currentHour >= _endHour) {
      return GuardResult.deny(
        DianaResponse(
          403,
          body: 'Access only allowed between $_startHour:00 and $_endHour:00',
        ),
      );
    }

    return GuardResult.allow();
  }
}
