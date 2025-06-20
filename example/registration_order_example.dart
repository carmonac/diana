import '../lib/src/core/service_locator.dart';
import '../lib/src/annotations/service.dart';

// Servicios de ejemplo para demostrar el problema
class DatabaseService {
  void connect() => print('Database connected');
}

class LoggerService {
  final DatabaseService db;
  LoggerService(this.db);
  void log(String msg) => print('LOG: $msg');
}

class EmailService {
  final LoggerService logger;
  EmailService(this.logger);
  void send(String to) => print('Email sent to $to');
}

class UserService {
  final EmailService emailService;
  final DatabaseService database;

  UserService(this.emailService, this.database);

  void createUser(String email) {
    database.connect();
    emailService.send(email);
    print('User created: $email');
  }
}

void main() {
  print('=== Service Registration Order Problem ===\n');

  demonstrateProblem();
  print('\n' + '=' * 50 + '\n');
  demonstrateSolutions();
}

void demonstrateProblem() {
  print('🚨 PROBLEMA: Registro en orden incorrecto\n');

  final serviceLocator = ServiceLocator.instance;
  serviceLocator.clear();

  print(
    '❌ Intentando registrar UserService primero (depende de EmailService)...',
  );

  try {
    // ❌ ESTO FALLA porque EmailService no está registrado aún
    serviceLocator.registerSingleton<UserService>(() {
      print('   Factory de UserService ejecutándose...');
      print('   Intentando obtener EmailService...');
      final emailService = serviceLocator.get<EmailService>(); // ¡BOOM!
      final database = serviceLocator.get<DatabaseService>();
      return UserService(emailService, database);
    });

    print('   ✅ UserService registrado (no debería llegar aquí)');
  } catch (e) {
    print('   ❌ ERROR al registrar UserService: $e');
  }

  print('\n❌ El problema es que el factory se ejecuta durante el registro');
  print(
    '   y llamamos a serviceLocator.get() antes de registrar las dependencias',
  );
}

void demonstrateSolutions() {
  print('✅ SOLUCIONES al problema de orden de registro\n');

  solution1_CorrectOrder();
  print('\n' + '-' * 30 + '\n');
  solution2_LazyFactories();
  print('\n' + '-' * 30 + '\n');
  solution3_AutoRegistration();
  print('\n' + '-' * 30 + '\n');
  solution4_BulkRegistration();
}

void solution1_CorrectOrder() {
  print('📋 Solución 1: Registro en orden correcto');

  final serviceLocator = ServiceLocator.instance;
  serviceLocator.clear();

  print('1. Registrando DatabaseService (sin dependencias)...');
  serviceLocator.registerSingleton<DatabaseService>(() {
    print('   Factory DatabaseService ejecutándose...');
    return DatabaseService();
  });

  print('2. Registrando LoggerService (depende de DatabaseService)...');
  serviceLocator.registerSingleton<LoggerService>(() {
    print('   Factory LoggerService ejecutándose...');
    final db = serviceLocator.get<DatabaseService>(); // DB ya está registrado
    return LoggerService(db);
  });

  print('3. Registrando EmailService (depende de LoggerService)...');
  serviceLocator.registerSingleton<EmailService>(() {
    print('   Factory EmailService ejecutándose...');
    final logger = serviceLocator
        .get<LoggerService>(); // Logger ya está registrado
    return EmailService(logger);
  });

  print('4. Registrando UserService (depende de Email y Database)...');
  serviceLocator.registerSingleton<UserService>(() {
    print('   Factory UserService ejecutándose...');
    final email = serviceLocator
        .get<EmailService>(); // Email ya está registrado
    final db = serviceLocator.get<DatabaseService>();
    return UserService(email, db);
  });

  print('\n✅ Todos los servicios registrados correctamente');
  print('✅ Obteniendo UserService...');
  final userService = serviceLocator.get<UserService>();
  userService.createUser('user@example.com');
}

void solution2_LazyFactories() {
  print('🔄 Solución 2: Factories que NO llaman get() durante registro');

  final serviceLocator = ServiceLocator.instance;
  serviceLocator.clear();

  print('Registrando servicios en cualquier orden...');

  // Podemos registrar en cualquier orden porque los factories no se ejecutan
  serviceLocator.registerSingleton<UserService>(() {
    // Esta función NO se ejecuta hasta que alguien pida UserService
    print('   Factory UserService ejecutándose (lazy)...');
    final email = serviceLocator.get<EmailService>();
    final db = serviceLocator.get<DatabaseService>();
    return UserService(email, db);
  });

  serviceLocator.registerSingleton<EmailService>(() {
    print('   Factory EmailService ejecutándose (lazy)...');
    final logger = serviceLocator.get<LoggerService>();
    return EmailService(logger);
  });

  serviceLocator.registerSingleton<DatabaseService>(() {
    print('   Factory DatabaseService ejecutándose (lazy)...');
    return DatabaseService();
  });

  serviceLocator.registerSingleton<LoggerService>(() {
    print('   Factory LoggerService ejecutándose (lazy)...');
    final db = serviceLocator.get<DatabaseService>();
    return LoggerService(db);
  });

  print('✅ Todos registrados sin ejecutar factories');
  print('✅ Obteniendo UserService (ahora se ejecutan los factories)...');
  final userService = serviceLocator.get<UserService>();
  userService.createUser('lazy@example.com');
}

void solution3_AutoRegistration() {
  print('🤖 Solución 3: Auto-registro con ServiceLocator mejorado');

  final serviceLocator = ServiceLocator.instance;
  serviceLocator.clear();

  print('Usando métodos Auto que pasan el ServiceLocator como parámetro...');

  // Registro con auto-resolución
  serviceLocator.registerSingletonAuto<DatabaseService>((locator) {
    print('   Auto factory DatabaseService...');
    return DatabaseService();
  });

  serviceLocator.registerSingletonAuto<LoggerService>((locator) {
    print('   Auto factory LoggerService...');
    final db = locator.get<DatabaseService>();
    return LoggerService(db);
  });

  serviceLocator.registerSingletonAuto<EmailService>((locator) {
    print('   Auto factory EmailService...');
    final logger = locator.get<LoggerService>();
    return EmailService(logger);
  });

  serviceLocator.registerSingletonAuto<UserService>((locator) {
    print('   Auto factory UserService...');
    final email = locator.get<EmailService>();
    final db = locator.get<DatabaseService>();
    return UserService(email, db);
  });

  print('✅ Auto-registro completado');
  print('✅ Obteniendo UserService...');
  final userService = serviceLocator.get<UserService>();
  userService.createUser('auto@example.com');
}

void solution4_BulkRegistration() {
  print('📦 Solución 4: Registro en lote (Bulk Registration)');

  final serviceLocator = ServiceLocator.instance;
  serviceLocator.clear();

  print('Definiendo todas las registraciones juntas...');

  final registrations = [
    // Podemos definir en cualquier orden
    ServiceRegistration<UserService>(
      serviceType: UserService,
      scope: ServiceScope.singleton,
      factory: (locator) {
        print('   Bulk factory UserService...');
        return UserService(
          locator.get<EmailService>(),
          locator.get<DatabaseService>(),
        );
      },
      dependencies: [EmailService, DatabaseService],
    ),

    ServiceRegistration<EmailService>(
      serviceType: EmailService,
      scope: ServiceScope.singleton,
      factory: (locator) {
        print('   Bulk factory EmailService...');
        return EmailService(locator.get<LoggerService>());
      },
      dependencies: [LoggerService],
    ),

    ServiceRegistration<LoggerService>(
      serviceType: LoggerService,
      scope: ServiceScope.singleton,
      factory: (locator) {
        print('   Bulk factory LoggerService...');
        return LoggerService(locator.get<DatabaseService>());
      },
      dependencies: [DatabaseService],
    ),

    ServiceRegistration<DatabaseService>(
      serviceType: DatabaseService,
      scope: ServiceScope.singleton,
      factory: (locator) {
        print('   Bulk factory DatabaseService...');
        return DatabaseService();
      },
      dependencies: [],
    ),
  ];

  print(
    '✅ Registrando todo en lote (el ServiceLocator ordena automáticamente)...',
  );
  serviceLocator.registerBulk(registrations);

  print('✅ Obteniendo UserService...');
  final userService = serviceLocator.get<UserService>();
  userService.createUser('bulk@example.com');
}

/// Ejemplo adicional: Qué pasa cuando registramos mal
void demonstrateWhatHappensWrong() {
  print('\n🔍 Análisis: ¿Por qué falla el registro incorrecto?\n');

  final serviceLocator = ServiceLocator.instance;
  serviceLocator.clear();

  print('⏰ TIMELINE del problema:');
  print('1. Llamamos registerSingleton<UserService>()');
  print(
    '2. Pasamos una función factory que contiene serviceLocator.get<EmailService>()',
  );
  print('3. ❌ PERO la función factory NO se guarda para después');
  print('4. ❌ La función factory se EJECUTA INMEDIATAMENTE');
  print('5. ❌ serviceLocator.get<EmailService>() se ejecuta AHORA');
  print('6. ❌ EmailService no está registrado → CRASH');

  print('\n✅ SOLUCIÓN - Lazy evaluation:');
  print('1. La función factory se guarda SIN ejecutar');
  print('2. Solo se ejecuta cuando alguien pide la instancia');
  print('3. Para entonces, todas las dependencias ya están registradas');

  print('\n📝 REGLA DE ORO:');
  print('   Los factories NUNCA deben ejecutarse durante el registro,');
  print('   solo cuando se solicita la instancia por primera vez.');
}
