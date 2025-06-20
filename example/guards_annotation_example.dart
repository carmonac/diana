import '../lib/diana.dart';
import 'package:shelf/shelf.dart' as shelf;

/// Example showing the new annotation-based Guards system
void main() async {
  print('=== Diana Guards Annotation-Based System ===\n');

  // Register guard factories
  GuardRegistry.registerCommonGuards();

  // Example of creating guards with annotation-style configuration
  await demonstrateAnnotationStyleGuards();
}

Future<void> demonstrateAnnotationStyleGuards() async {
  print('1. Annotation-Style Guards Example');
  print('==================================');

  // Create a RoleGuard with configuration similar to how it would work with annotations
  final roleGuard = GuardProcessor.createGuardInstance(RoleGuard, {
    'roles': ['admin'],
  });

  if (roleGuard != null) {
    print('✅ RoleGuard created successfully with config: ${roleGuard.config}');

    // Test the guard
    final request = createMockRequest(
      context: {
        'user': {
          'id': 'user123',
          'roles': ['admin', 'user'],
          'authenticated': true,
        },
      },
    );

    final result = await roleGuard.canActivate(request, roleGuard.config);
    print('Guard result - canActivate: ${result.canActivate}');
  }

  // Create an AuthGuard with configuration
  final authGuard = GuardProcessor.createGuardInstance(AuthGuard, {
    'secretKey': 'demo-secret',
    'tokenHeaderName': 'authorization',
  });

  if (authGuard != null) {
    print('✅ AuthGuard created successfully with config: ${authGuard.config}');

    // Test the guard
    final requestWithToken = createMockRequest(
      headers: {'authorization': 'Bearer demo-secret-valid-token'},
    );

    final result = await authGuard.canActivate(
      requestWithToken,
      authGuard.config,
    );
    print('Auth guard result - canActivate: ${result.canActivate}');
  }

  // Demonstrate executing multiple guards in sequence
  print('\n2. Multiple Guards Execution');
  print('============================');

  final guards = <DianaGuard>[];

  final auth = GuardProcessor.createGuardInstance(AuthGuard, {
    'secretKey': 'test-secret',
  });
  final role = GuardProcessor.createGuardInstance(RoleGuard, {
    'roles': ['admin'],
  });

  if (auth != null) guards.add(auth);
  if (role != null) guards.add(role);

  final requestForMultiple = createMockRequest(
    headers: {'authorization': 'Bearer test-secret-token'},
    context: {
      'user': {
        'id': 'admin123',
        'roles': ['admin'],
        'authenticated': true,
      },
    },
  );

  final combinedResult = await GuardProcessor.executeGuards(
    guards,
    requestForMultiple,
  );
  print('Combined guards result - canActivate: ${combinedResult.canActivate}');
  print('Combined guards context data: ${combinedResult.contextData}');

  print('\n3. Custom Guard Example');
  print('=======================');

  // Register and use a custom guard
  GuardProcessor.registerGuardFactory<TimeBasedGuard>(
    () => TimeBasedGuard(startHour: 9, endHour: 17),
  );

  final timeGuard = GuardProcessor.createGuardInstance(TimeBasedGuard, {
    'startHour': 0,
    'endHour': 23,
  });

  if (timeGuard != null) {
    print('✅ TimeBasedGuard created successfully');

    final result = await timeGuard.canActivate(createMockRequest());
    print('Time guard result - canActivate: ${result.canActivate}');
  }
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

/// Custom guard for demonstration
class TimeBasedGuard extends DianaGuard {
  int startHour;
  int endHour;

  TimeBasedGuard({required this.startHour, required this.endHour});

  @override
  Future<GuardResult> canActivate(
    DianaRequest request, [
    Map<String, dynamic>? config,
  ]) async {
    // Apply configuration if provided
    if (config != null) {
      startHour = config['startHour'] ?? startHour;
      endHour = config['endHour'] ?? endHour;
    }

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
