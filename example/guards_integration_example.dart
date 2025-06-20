import '../lib/diana.dart';
import 'package:shelf/shelf.dart' as shelf;

/// Comprehensive example showing Guards integration with Diana framework
/// This demonstrates real-world usage patterns

void main() async {
  print('=== Diana Guards Integration Examples ===\n');

  // Example 1: Basic route protection
  await basicRouteProtectionExample();

  // Example 2: Multi-level authorization
  await multiLevelAuthExample();

  // Example 3: API rate limiting
  await apiRateLimitingExample();

  // Example 4: Custom guard combinations
  await customGuardCombinationsExample();

  // Example 5: Context data flow
  await contextDataFlowExample();
}

/// Example 1: Basic route protection with authentication
Future<void> basicRouteProtectionExample() async {
  print('1. Basic Route Protection Example');
  print('==================================');

  // Simulate a protected route handler
  final protectedHandler = (DianaRequest req) async {
    final user = req.getContext<Map<String, Object?>>('user');
    return DianaResponse.json({
      'message': 'Welcome to protected area!',
      'user': user?['id'],
      'authenticated': user?['authenticated'],
    });
  };

  // Create authentication middleware
  final authMiddleware = Guards.auth(secretKey: 'demo-secret-key');

  // Test with valid token
  print('Testing with valid token...');
  final validRequest = createMockRequest(
    headers: {'authorization': 'Bearer demo-secret-key-valid-token'},
  );

  final response1 = await authMiddleware.handle(validRequest, protectedHandler);
  print('Status: ${response1.statusCode}');

  // Test without token
  print('Testing without token...');
  final invalidRequest = createMockRequest();
  final response2 = await authMiddleware.handle(
    invalidRequest,
    protectedHandler,
  );
  print('Status: ${response2.statusCode}');

  print('');
}

/// Example 2: Multi-level authorization (Auth + Roles)
Future<void> multiLevelAuthExample() async {
  print('2. Multi-level Authorization Example');
  print('====================================');

  final adminHandler = (DianaRequest req) async {
    final user = req.getContext<Map<String, Object?>>('user');
    return DianaResponse.json({
      'message': 'Admin panel access granted',
      'user': user,
    });
  };

  // Create combined auth + role middleware
  final adminMiddleware = Guards.combine([
    AuthGuard(customTokenValidator: (token) => token == 'admin-token'),
    RoleGuard(requiredRoles: ['admin']),
  ]);

  // Test with admin user (need to simulate the full flow)
  print('Testing admin access flow...');

  // First, test authentication guard alone
  final authOnlyGuard = AuthGuard(
    customTokenValidator: (token) => token == 'admin-token',
  );

  final adminAuthRequest = createMockRequest(
    headers: {'authorization': 'admin-token'},
  );

  final authResult = await authOnlyGuard.canActivate(adminAuthRequest);
  print('Auth guard result: ${authResult.canActivate}');

  // Then test role guard with user context
  final roleGuard = RoleGuard(requiredRoles: ['admin']);
  final adminUserRequest = createMockRequest(
    context: {
      'user': {
        'id': 'admin123',
        'roles': ['admin', 'user'],
        'authenticated': true,
      },
    },
  );

  final roleResult = await roleGuard.canActivate(adminUserRequest);
  print('Role guard result: ${roleResult.canActivate}');

  print('');
}

/// Example 3: API rate limiting
Future<void> apiRateLimitingExample() async {
  print('3. API Rate Limiting Example');
  print('============================');

  final apiHandler = (DianaRequest req) async {
    return DianaResponse.json({
      'data': 'API response',
      'timestamp': DateTime.now().toIso8601String(),
    });
  };

  // Create rate limiting middleware (2 requests per minute for demo)
  final rateLimitMiddleware = Guards.rateLimit(
    maxRequests: 2,
    timeWindow: Duration(minutes: 1),
  );

  final request = createMockRequest();

  // First request - should succeed
  print('Request 1...');
  final response1 = await rateLimitMiddleware.handle(request, apiHandler);
  print('Status: ${response1.statusCode}');

  // Second request - should succeed
  print('Request 2...');
  final response2 = await rateLimitMiddleware.handle(request, apiHandler);
  print('Status: ${response2.statusCode}');

  // Third request - should fail (rate limited)
  print('Request 3...');
  final response3 = await rateLimitMiddleware.handle(request, apiHandler);
  print('Status: ${response3.statusCode}');

  print('');
}

/// Example 4: Custom guard combinations
Future<void> customGuardCombinationsExample() async {
  print('4. Custom Guard Combinations Example');
  print('====================================');

  // Test individual custom guards
  print('Testing TimeBasedGuard...');
  final timeGuard = TimeBasedGuard(
    startHour: 0,
    endHour: 23,
  ); // Allow all day for demo
  final timeResult = await timeGuard.canActivate(createMockRequest());
  print('Time guard result: ${timeResult.canActivate}');

  print('Testing IPWhitelistGuard...');
  final ipGuard = IPWhitelistGuard(['unknown']); // Allow 'unknown' for demo
  final ipResult = await ipGuard.canActivate(createMockRequest());
  print('IP guard result: ${ipResult.canActivate}');

  print('Testing combined custom guards...');
  final customMiddleware = GuardMiddleware([
    TimeBasedGuard(startHour: 0, endHour: 23),
    IPWhitelistGuard(['unknown']),
  ]);

  final customHandler = (DianaRequest req) async {
    return DianaResponse.json({'message': 'Custom guards passed!'});
  };

  final response = await customMiddleware.handle(
    createMockRequest(),
    customHandler,
  );
  print('Combined custom guards status: ${response.statusCode}');

  print('');
}

/// Example 5: Context data flow between guards
Future<void> contextDataFlowExample() async {
  print('5. Context Data Flow Example');
  print('============================');

  // Test individual guards and their context data
  print('Testing individual guards context data...');

  final authGuard = AuthGuard(
    customTokenValidator: (token) => token == 'context-token',
  );

  final authRequest = createMockRequest(
    headers: {'authorization': 'context-token'},
  );

  final authResult = await authGuard.canActivate(authRequest);
  print('Auth guard - canActivate: ${authResult.canActivate}');
  print('Auth guard - context data: ${authResult.contextData}');

  final permissionsGuard = PermissionsGuard();
  final userRequest = createMockRequest(
    context: {
      'user': {
        'id': 'user123',
        'roles': ['admin'],
        'authenticated': true,
      },
    },
  );

  final permResult = await permissionsGuard.canActivate(userRequest);
  print('Permissions guard - canActivate: ${permResult.canActivate}');
  print('Permissions guard - context data: ${permResult.contextData}');

  print('');
}

// Helper function to create mock requests
DianaRequest createMockRequest({
  Map<String, String>? headers,
  Map<String, Object?>? context,
}) {
  final shelfRequest = shelf.Request(
    'GET',
    Uri.parse('http://localhost/test'),
    headers: headers ?? {},
    context: context?.cast<String, Object>() ?? {},
  );
  return DianaRequest.fromShelf(shelfRequest);
}

// Custom guards for demonstration

/// Time-based access guard
class TimeBasedGuard extends DianaGuard {
  final int startHour;
  final int endHour;

  TimeBasedGuard({required this.startHour, required this.endHour});

  @override
  Future<GuardResult> canActivate(DianaRequest request) async {
    final now = DateTime.now();
    final currentHour = now.hour;

    if (currentHour < startHour || currentHour >= endHour) {
      return GuardResult.deny(
        DianaResponse(
          403,
          body: 'Access only allowed between $startHour:00 and $endHour:00',
        ),
      );
    }

    return GuardResult.allow(contextData: {'timeChecked': true});
  }
}

/// IP whitelist guard
class IPWhitelistGuard extends DianaGuard {
  final List<String> allowedIPs;

  IPWhitelistGuard(this.allowedIPs);

  @override
  Future<GuardResult> canActivate(DianaRequest request) async {
    final clientIP =
        request.header('x-forwarded-for') ??
        request.header('x-real-ip') ??
        'unknown';

    if (!allowedIPs.contains(clientIP)) {
      return GuardResult.forbidden('IP address not allowed: $clientIP');
    }

    return GuardResult.allow(contextData: {'clientIP': clientIP});
  }
}

/// Custom guard that adds user permissions
class PermissionsGuard extends DianaGuard {
  @override
  Future<GuardResult> canActivate(DianaRequest request) async {
    final user = request.getContext<Map<String, Object?>>('user');

    if (user == null) {
      return GuardResult.unauthorized('User not found');
    }

    // Simulate fetching permissions based on user roles
    final roles = user['roles'] as List<String>? ?? [];
    final permissions = <String>[];

    if (roles.contains('admin')) {
      permissions.addAll(['read', 'write', 'delete', 'admin']);
    } else if (roles.contains('user')) {
      permissions.addAll(['read', 'write']);
    }

    return GuardResult.allow(contextData: {'permissions': permissions});
  }
}
