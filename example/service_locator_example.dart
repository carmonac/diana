import 'package:diana/src/core/service_locator.dart';
import 'package:diana/src/annotations/service.dart';

// Ejemplo de servicios con diferentes scopes

@Service(scope: ServiceScope.singleton)
class DatabaseService implements Disposable {
  String connection = 'Connected to DB';

  void query(String sql) {
    print('Executing: $sql');
  }

  @override
  void dispose() {
    print('DatabaseService disposed');
  }
}

@Service(scope: ServiceScope.transient)
class EmailService {
  final String provider;

  EmailService({this.provider = 'default'});

  void sendEmail(String to, String subject) {
    print('Sending email to $to with subject: $subject via $provider');
  }
}

@Service(scope: ServiceScope.scoped)
class UserContextService implements Disposable {
  final String userId;
  final DateTime sessionStart;

  UserContextService(this.userId) : sessionStart = DateTime.now();

  void logAction(String action) {
    print('User $userId performed: $action at ${DateTime.now()}');
  }

  @override
  void dispose() {
    print('UserContextService for user $userId disposed');
  }
}

@Service(scope: ServiceScope.singleton)
class LoggerService {
  void log(String message) {
    print('[${DateTime.now()}] $message');
  }
}

void main() {
  final serviceLocator = ServiceLocator.instance;

  print('=== Registering Services ===');

  // Registrar servicios singleton
  serviceLocator.registerSingleton<DatabaseService>(() => DatabaseService());
  serviceLocator.registerSingleton<LoggerService>(() => LoggerService());

  // Registrar servicios transient
  serviceLocator.registerTransient<EmailService>(
    () => EmailService(provider: 'Gmail'),
  );

  // Registrar servicios scoped
  serviceLocator.registerScoped<UserContextService>(
    () => UserContextService('user123'),
  );

  print('\n=== Testing Singleton Services ===');
  // Los singleton siempre devuelven la misma instancia
  final db1 = serviceLocator.get<DatabaseService>();
  final db2 = serviceLocator.get<DatabaseService>();
  print('Singleton instances are same: ${identical(db1, db2)}'); // true

  db1.query('SELECT * FROM users');

  print('\n=== Testing Transient Services ===');
  // Los transient siempre crean nuevas instancias
  final email1 = serviceLocator.get<EmailService>();
  final email2 = serviceLocator.get<EmailService>();
  print(
    'Transient instances are different: ${!identical(email1, email2)}',
  ); // true

  email1.sendEmail('user@example.com', 'Welcome!');

  print('\n=== Testing Scoped Services ===');
  // Los scoped requieren un scope activo
  try {
    serviceLocator.get<UserContextService>(); // Esto fallará
  } catch (e) {
    print('Error sin scope: $e');
  }

  // Iniciamos un scope
  serviceLocator.beginScope('request-1');

  final user1 = serviceLocator.get<UserContextService>();
  final user2 = serviceLocator.get<UserContextService>();
  print(
    'Scoped instances in same scope are same: ${identical(user1, user2)}',
  ); // true

  user1.logAction('login');
  user1.logAction('view profile');

  // Terminamos el scope
  serviceLocator.endScope();

  print('\n=== Testing Different Scopes ===');
  // Nuevo scope
  serviceLocator.beginScope('request-2');
  final user3 = serviceLocator.get<UserContextService>();
  print('New scope creates new instance: ${!identical(user1, user3)}'); // true

  user3.logAction('logout');
  serviceLocator.endScope();

  print('\n=== Testing Service Registration by Scope ===');
  // También puedes registrar usando el enum directamente
  serviceLocator.registerService<LoggerService>(
    () => LoggerService(),
    ServiceScope.singleton,
  );

  final logger = serviceLocator.get<LoggerService>();
  logger.log('Service locator example completed');

  print('\n=== Testing Service Checks ===');
  print(
    'DatabaseService is registered: ${serviceLocator.isRegistered<DatabaseService>()}',
  );
  print(
    'Unknown service is registered: ${serviceLocator.isRegistered<String>()}',
  );

  final maybeLogger = serviceLocator.tryGet<LoggerService>();
  final maybeUnknown = serviceLocator.tryGet<String>();
  print('TryGet logger: ${maybeLogger != null}');
  print('TryGet unknown: ${maybeUnknown != null}');
}
