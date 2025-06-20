import '../lib/src/core/service_locator.dart';
import '../lib/src/annotations/service.dart';

// Servicios de ejemplo para demostrar problemas de dependencias

@Service(scope: ServiceScope.singleton)
class DatabaseService {
  final String connectionString;

  DatabaseService({this.connectionString = 'localhost:5432'});

  void connect() {
    print('Connected to database: $connectionString');
  }
}

@Service(scope: ServiceScope.singleton)
class EmailService {
  final LoggerService logger;

  EmailService(this.logger);

  void sendEmail(String to, String subject) {
    logger.log('Sending email to $to: $subject');
    print('Email sent successfully');
  }
}

@Service(scope: ServiceScope.singleton)
class LoggerService {
  final DatabaseService database;

  LoggerService(this.database);

  void log(String message) {
    database.connect();
    print('[${DateTime.now()}] $message');
  }
}

// Ejemplo de dependencia circular
@Service(scope: ServiceScope.singleton)
class ServiceA {
  final ServiceB serviceB;

  ServiceA(this.serviceB);

  void doSomething() {
    print('ServiceA doing something');
    serviceB.doSomethingElse();
  }
}

@Service(scope: ServiceScope.singleton)
class ServiceB {
  final ServiceA serviceA;

  ServiceB(this.serviceA);

  void doSomethingElse() {
    print('ServiceB doing something else');
    serviceA.doSomething();
  }
}

@Service(scope: ServiceScope.transient)
class UserService {
  final EmailService emailService;
  final DatabaseService database;

  UserService(this.emailService, this.database);

  void createUser(String email) {
    database.connect();
    emailService.sendEmail(email, 'Welcome!');
    print('User created: $email');
  }
}

void main() {
  print('=== Diana ServiceLocator - Dependency Management Examples ===\n');

  final serviceLocator = ServiceLocator.instance;

  // Limpiar state anterior
  serviceLocator.clear();

  print('🧪 Test 1: Servicio No Registrado');
  demonstrateUnregisteredService();

  print('\n🧪 Test 2: Dependencias Correctas');
  demonstrateCorrectDependencies();

  print('\n🧪 Test 3: Dependencia Circular');
  demonstrateCircularDependency();

  print('\n🧪 Test 4: Validación de Dependencias');
  demonstrateDependencyValidation();

  print('\n🧪 Test 5: Información de Servicios');
  demonstrateServiceInfo();
}

void demonstrateUnregisteredService() {
  final serviceLocator = ServiceLocator.instance;
  serviceLocator.clear();

  print('❌ Intentando obtener EmailService sin registrarlo...');

  try {
    final email = serviceLocator.get<EmailService>();
    print('Esto no debería ejecutarse: $email');
  } on ServiceNotRegisteredException catch (e) {
    print('✅ Excepción capturada correctamente: ${e.message}');
  }

  // Usando safeGet
  final safeEmail = serviceLocator.safeGet<EmailService>();
  print('✅ SafeGet retorna: $safeEmail (null como esperado)');
}

void demonstrateCorrectDependencies() {
  final serviceLocator = ServiceLocator.instance;
  serviceLocator.clear();

  print('✅ Registrando servicios en orden correcto...');

  // Registrar en orden correcto (sin dependencias primero)
  serviceLocator.registerSingleton<DatabaseService>(() => DatabaseService());
  serviceLocator.registerSingleton<LoggerService>(() {
    final db = serviceLocator.get<DatabaseService>();
    return LoggerService(db);
  });
  serviceLocator.registerSingleton<EmailService>(() {
    final logger = serviceLocator.get<LoggerService>();
    return EmailService(logger);
  });
  serviceLocator.registerTransient<UserService>(() {
    final email = serviceLocator.get<EmailService>();
    final db = serviceLocator.get<DatabaseService>();
    return UserService(email, db);
  });

  print(
    '✅ Creando UserService (que depende de EmailService y DatabaseService)...',
  );
  final userService = serviceLocator.get<UserService>();
  userService.createUser('user@example.com');
}

void demonstrateCircularDependency() {
  final serviceLocator = ServiceLocator.instance;
  serviceLocator.clear();

  print('❌ Registrando servicios con dependencia circular...');

  // Registrar servicios con dependencia circular
  serviceLocator.registerSingleton<ServiceA>(() {
    final serviceB = serviceLocator.get<ServiceB>();
    return ServiceA(serviceB);
  });

  serviceLocator.registerSingleton<ServiceB>(() {
    final serviceA = serviceLocator.get<ServiceA>();
    return ServiceB(serviceA);
  });

  print('❌ Intentando obtener ServiceA (que crea una dependencia circular)...');

  try {
    final serviceA = serviceLocator.get<ServiceA>();
    print('Esto no debería ejecutarse: $serviceA');
  } on CircularDependencyException catch (e) {
    print('✅ Dependencia circular detectada: ${e.message}');
  }
}

void demonstrateDependencyValidation() {
  final serviceLocator = ServiceLocator.instance;
  serviceLocator.clear();

  print('🔍 Validando dependencias...');

  // Configuración con problemas
  serviceLocator.registerSingleton<EmailService>(() {
    final logger = serviceLocator
        .get<LoggerService>(); // LoggerService no registrado
    return EmailService(logger);
  });

  serviceLocator.registerSingleton<ServiceA>(() {
    final serviceB = serviceLocator.get<ServiceB>();
    return ServiceA(serviceB);
  });

  serviceLocator.registerSingleton<ServiceB>(() {
    final serviceA = serviceLocator.get<ServiceA>();
    return ServiceB(serviceA);
  });

  final errors = serviceLocator.validateDependencies();

  if (errors.isEmpty) {
    print('✅ Todas las dependencias son válidas');
  } else {
    print('❌ Errores de dependencias encontrados:');
    for (final error in errors) {
      print('   - $error');
    }
  }
}

void demonstrateServiceInfo() {
  final serviceLocator = ServiceLocator.instance;
  serviceLocator.clear();

  print('📊 Información de servicios...');

  // Registrar algunos servicios
  serviceLocator.registerSingleton<DatabaseService>(() => DatabaseService());
  serviceLocator.registerTransient<EmailService>(
    () => EmailService(serviceLocator.get<LoggerService>()),
  );
  serviceLocator.registerScoped<UserService>(
    () => UserService(
      serviceLocator.get<EmailService>(),
      serviceLocator.get<DatabaseService>(),
    ),
  );

  // Obtener información
  print('DatabaseService: ${serviceLocator.getServiceInfo<DatabaseService>()}');
  print('EmailService: ${serviceLocator.getServiceInfo<EmailService>()}');
  print('UserService: ${serviceLocator.getServiceInfo<UserService>()}');
  print('UnregisteredService: ${serviceLocator.getServiceInfo<String>()}');

  print('\n📋 Tipos registrados: ${serviceLocator.getRegisteredTypes()}');

  // Crear una instancia singleton
  final db = serviceLocator.get<DatabaseService>();
  print(
    'DatabaseService después de crear instancia: ${serviceLocator.getServiceInfo<DatabaseService>()}',
  );
}

/// Ejemplo de uso seguro en producción
void productionExample() {
  final serviceLocator = ServiceLocator.instance;

  print('\n🏭 Ejemplo de Uso en Producción:');

  // 1. Registrar servicios en orden de dependencias (bottom-up)
  registerServices(serviceLocator);

  // 2. Validar dependencias antes de usar
  final errors = serviceLocator.validateDependencies();
  if (errors.isNotEmpty) {
    print('❌ Errores de configuración detectados:');
    for (final error in errors) {
      print('   $error');
    }
    return;
  }

  // 3. Usar servicios de forma segura
  final userService = serviceLocator.safeGet<UserService>();
  if (userService != null) {
    userService.createUser('production@example.com');
  } else {
    print('❌ UserService no disponible');
  }
}

void registerServices(ServiceLocator serviceLocator) {
  // Orden correcto: servicios sin dependencias primero
  serviceLocator.registerSingleton<DatabaseService>(() => DatabaseService());

  serviceLocator.registerSingleton<LoggerService>(
    () => LoggerService(serviceLocator.get<DatabaseService>()),
  );

  serviceLocator.registerSingleton<EmailService>(
    () => EmailService(serviceLocator.get<LoggerService>()),
  );

  serviceLocator.registerTransient<UserService>(
    () => UserService(
      serviceLocator.get<EmailService>(),
      serviceLocator.get<DatabaseService>(),
    ),
  );
}
