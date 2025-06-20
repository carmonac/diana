import '../lib/diana.dart';
import 'package:shelf/shelf.dart' as shelf;

/// Example showing how to use Guards with annotations in controllers
/// This demonstrates the intended usage pattern you described

void main() async {
  print('=== Diana Guards with Annotations - Real Usage ===\n');

  // Register guard factories first
  GuardRegistry.registerCommonGuards();

  // Register custom guards
  GuardProcessor.registerGuardFactory<RoleGuard>(
    () => RoleGuard(requiredRoles: []),
  );

  // Simulate controller guard processing
  await demonstrateControllerGuards();
}

Future<void> demonstrateControllerGuards() async {
  print('1. Controller with Class-level Guards');
  print('====================================');

  // Simulate @Guard(RoleGuard, {'role': 'admin'}) on controller
  final classGuards = [
    GuardProcessor.createGuardInstance(RoleGuard, {
      'roles': ['admin'],
    }),
  ].whereType<DianaGuard>().toList();

  print('✅ Class-level guards created: ${classGuards.length}');

  // Simulate a request to the controller
  final request = createMockRequest(
    context: {
      'user': {
        'id': 'admin123',
        'roles': ['admin'],
        'authenticated': true,
      },
    },
  );

  final result = await GuardProcessor.executeGuards(classGuards, request);
  print('Controller access result: ${result.canActivate}');

  print('\n2. Method-level Guards Override');
  print('===============================');

  // Simulate additional method-level guards
  final methodGuards = [
    GuardProcessor.createGuardInstance(AuthGuard, {
      'secretKey': 'method-secret',
    }),
  ].whereType<DianaGuard>().toList();

  // Combine class and method guards
  final allGuards = [...classGuards, ...methodGuards];

  final requestWithAuth = createMockRequest(
    headers: {'authorization': 'Bearer method-secret-token'},
    context: {
      'user': {
        'id': 'admin123',
        'roles': ['admin'],
        'authenticated': true,
      },
    },
  );

  final methodResult = await GuardProcessor.executeGuards(
    allGuards,
    requestWithAuth,
  );
  print('Method access result: ${methodResult.canActivate}');

  print('\n3. Injectable Guards with Dependencies');
  print('======================================');

  // Simulate a guard that uses dependency injection
  final loggerGuard = LoggerGuard();
  loggerGuard.setConfig({'logLevel': 'info'});

  final logResult = await loggerGuard.canActivate(request);
  print('Logger guard result: ${logResult.canActivate}');
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

/// Example of a guard that would be Injectable
@Injectable()
class LoggerGuard extends DianaGuard {
  // In a real scenario, this would be injected
  final Logger logger = Logger();

  @override
  Future<GuardResult> canActivate(
    DianaRequest request, [
    Map<String, dynamic>? config,
  ]) async {
    final logLevel = config?['logLevel'] ?? 'debug';

    logger.log('Guard executed with level: $logLevel');
    logger.log('Request: ${request.method} ${request.uri}');

    return GuardResult.allow(contextData: {'logged': true});
  }
}

/// Example Logger class (would normally be injected)
@Injectable()
class Logger {
  void log(String message) {
    print('[LOG] $message');
  }
}

/// Example controller that would use guards with annotations
/// This shows the intended usage pattern:

/*
@Injectable()
class RoleGuard extends DianaGuard {
  Logger logger;
  
  RoleGuard(this.logger);

  @override
  Future<GuardResult> canActivate(DianaRequest request, [Map<String, dynamic>? config]) async {
    final requiredRole = config?['role'] ?? 'user';
    logger.log('Checking role: $requiredRole');
    
    final user = request.getContext<Map<String, Object?>>('user');
    final userRoles = user?['roles'] as List<String>? ?? [];
    
    if (!userRoles.contains(requiredRole)) {
      return GuardResult.forbidden('Required role: $requiredRole');
    }
    
    return GuardResult.allow();
  }
}

@Guard(RoleGuard, {'role': 'admin'})
@Controller('/admin')
class AdminController {
  
  @Get('/users')
  Future<DianaResponse> getUsers() async {
    return DianaResponse.json(['user1', 'user2']);
  }
  
  @Guard(AuthGuard, {'secretKey': 'super-secret'})
  @Post('/users')
  Future<DianaResponse> createUser(@Body() Map<String, dynamic> user) async {
    return DianaResponse.json({'id': 1, ...user});
  }
}
*/
