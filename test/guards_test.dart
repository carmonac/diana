import 'package:test/test.dart';
import 'package:shelf/shelf.dart' as shelf;
import '../lib/diana.dart';

void main() {
  group('Guards Tests', () {
    late DianaRequest mockRequest;

    setUp(() {
      // Create a mock request for testing
      final shelfRequest = shelf.Request(
        'GET',
        Uri.parse('http://localhost/test'),
        headers: {},
      );
      mockRequest = DianaRequest.fromShelf(shelfRequest);
    });

    group('AuthGuard', () {
      test('should deny access without token', () async {
        final guard = AuthGuard(secretKey: 'test-secret');

        final result = await guard.canActivate(mockRequest);

        expect(result.canActivate, isFalse);
        expect(result.response, isNotNull);
        expect(result.response!.statusCode, equals(401));
      });

      test('should allow access with valid token', () async {
        final guard = AuthGuard(secretKey: 'test-secret');
        final shelfRequestWithToken = shelf.Request(
          'GET',
          Uri.parse('http://localhost/test'),
          headers: {'authorization': 'Bearer test-secret-token'},
        );
        final requestWithToken = DianaRequest.fromShelf(shelfRequestWithToken);

        final result = await guard.canActivate(requestWithToken);

        expect(result.canActivate, isTrue);
        expect(result.contextData, isNotNull);
        expect(result.contextData!['user'], isNotNull);
      });

      test('should work with custom validator', () async {
        final guard = AuthGuard(
          customTokenValidator: (token) => token.startsWith('valid-'),
        );
        final shelfRequestWithValidToken = shelf.Request(
          'GET',
          Uri.parse('http://localhost/test'),
          headers: {'authorization': 'valid-test-token'},
        );
        final requestWithValidToken = DianaRequest.fromShelf(
          shelfRequestWithValidToken,
        );

        final result = await guard.canActivate(requestWithValidToken);

        expect(result.canActivate, isTrue);
      });

      test('should deny access with invalid custom token', () async {
        final guard = AuthGuard(
          customTokenValidator: (token) => token.startsWith('valid-'),
        );
        final shelfRequestWithInvalidToken = shelf.Request(
          'GET',
          Uri.parse('http://localhost/test'),
          headers: {'authorization': 'invalid-test-token'},
        );
        final requestWithInvalidToken = DianaRequest.fromShelf(
          shelfRequestWithInvalidToken,
        );

        final result = await guard.canActivate(requestWithInvalidToken);

        expect(result.canActivate, isFalse);
        expect(result.response!.statusCode, equals(401));
      });
    });

    group('RoleGuard', () {
      test('should allow access with correct role', () async {
        final guard = RoleGuard(requiredRoles: ['admin']);
        final requestWithUser = mockRequest.copyWith(
          context: {
            'user': {
              'id': 'user123',
              'roles': ['admin', 'user'],
            },
          },
        );

        final result = await guard.canActivate(requestWithUser);

        expect(result.canActivate, isTrue);
      });

      test('should deny access without required role', () async {
        final guard = RoleGuard(requiredRoles: ['admin']);
        final requestWithUser = mockRequest.copyWith(
          context: {
            'user': {
              'id': 'user123',
              'roles': ['user'],
            },
          },
        );

        final result = await guard.canActivate(requestWithUser);

        expect(result.canActivate, isFalse);
        expect(result.response!.statusCode, equals(403));
      });

      test('should deny access without user info', () async {
        final guard = RoleGuard(requiredRoles: ['admin']);

        final result = await guard.canActivate(mockRequest);

        expect(result.canActivate, isFalse);
        expect(result.response!.statusCode, equals(401));
      });

      test('should work with single role as string', () async {
        final guard = RoleGuard(requiredRoles: ['admin']);
        final requestWithUser = mockRequest.copyWith(
          context: {
            'user': {
              'id': 'user123',
              'roles': 'admin', // Single role as string
            },
          },
        );

        final result = await guard.canActivate(requestWithUser);

        expect(result.canActivate, isTrue);
      });
    });

    group('RateLimitGuard', () {
      test('should allow requests within limit', () async {
        final guard = RateLimitGuard(
          maxRequests: 5,
          timeWindow: Duration(minutes: 1),
        );

        // First request should be allowed
        final result1 = await guard.canActivate(mockRequest);
        expect(result1.canActivate, isTrue);

        // Second request should also be allowed
        final result2 = await guard.canActivate(mockRequest);
        expect(result2.canActivate, isTrue);
      });

      test('should deny requests exceeding limit', () async {
        final guard = RateLimitGuard(
          maxRequests: 2,
          timeWindow: Duration(minutes: 1),
        );

        // First two requests should be allowed
        await guard.canActivate(mockRequest);
        await guard.canActivate(mockRequest);

        // Third request should be denied
        final result = await guard.canActivate(mockRequest);
        expect(result.canActivate, isFalse);
        expect(result.response!.statusCode, equals(429));
      });
    });

    group('GuardResult', () {
      test('should create allow result', () {
        final result = GuardResult.allow();
        expect(result.canActivate, isTrue);
        expect(result.response, isNull);
        expect(result.contextData, isNull);
      });

      test('should create allow result with context data', () {
        final contextData = {'user': 'test'};
        final result = GuardResult.allow(contextData: contextData);
        expect(result.canActivate, isTrue);
        expect(result.contextData, equals(contextData));
      });

      test('should create deny result', () {
        final response = DianaResponse(403, body: 'Forbidden');
        final result = GuardResult.deny(response);
        expect(result.canActivate, isFalse);
        expect(result.response, equals(response));
      });

      test('should create unauthorized result', () {
        final result = GuardResult.unauthorized('Token required');
        expect(result.canActivate, isFalse);
        expect(result.response!.statusCode, equals(401));
      });

      test('should create forbidden result', () {
        final result = GuardResult.forbidden('Access denied');
        expect(result.canActivate, isFalse);
        expect(result.response!.statusCode, equals(403));
      });
    });

    group('GuardMiddleware', () {
      test('should execute single guard correctly', () async {
        final authGuard = AuthGuard(secretKey: 'test');
        final middleware = GuardMiddleware.single(authGuard);

        bool nextCalled = false;
        final next = (DianaRequest req) async {
          nextCalled = true;
          return DianaResponse.ok('Success');
        };

        final result = await middleware.handle(mockRequest, next);

        // Should be denied (no auth token) and next should not be called
        expect(result.statusCode, equals(401));
        expect(nextCalled, isFalse);
      });

      test('should call next when guard allows', () async {
        final authGuard = AuthGuard(
          customTokenValidator: (token) => true, // Always allow
        );
        final middleware = GuardMiddleware.single(authGuard);

        final shelfRequestWithToken = shelf.Request(
          'GET',
          Uri.parse('http://localhost/test'),
          headers: {'authorization': 'any-token'},
        );
        final requestWithToken = DianaRequest.fromShelf(shelfRequestWithToken);

        bool nextCalled = false;
        final next = (DianaRequest req) async {
          nextCalled = true;
          return DianaResponse.ok('Success');
        };

        final result = await middleware.handle(requestWithToken, next);

        // Should be allowed and next should be called
        expect(result.statusCode, equals(200));
        expect(nextCalled, isTrue);
      });
    });

    group('Guards utility class', () {
      test('should create auth middleware', () {
        final middleware = Guards.auth(secretKey: 'test');
        expect(middleware, isA<GuardMiddleware>());
      });

      test('should create role middleware', () {
        final middleware = Guards.roles(['admin']);
        expect(middleware, isA<GuardMiddleware>());
      });

      test('should create rate limit middleware', () {
        final middleware = Guards.rateLimit(
          maxRequests: 10,
          timeWindow: Duration(minutes: 1),
        );
        expect(middleware, isA<GuardMiddleware>());
      });

      test('should create combined middleware', () {
        final middleware = Guards.authAndRoles(['admin']);
        expect(middleware, isA<GuardMiddleware>());
      });

      test('should create combined guards middleware', () {
        final guards = [
          AuthGuard(secretKey: 'test'),
          RoleGuard(requiredRoles: ['admin']),
        ];
        final middleware = Guards.combine(guards);
        expect(middleware, isA<GuardMiddleware>());
      });
    });
  });
}
