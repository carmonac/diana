import '../lib/src/core/service_locator.dart';
import '../lib/src/annotations/service.dart';

/// Simulación de un sistema de registro automático de servicios
/// basado en anotaciones (como el que tendrías en tu framework)

// Servicios de ejemplo con anotaciones
@Service(scope: ServiceScope.singleton)
class DatabaseService {
  void connect() => print('Database connected');
}

@Service(scope: ServiceScope.singleton)
class LoggerService {
  final DatabaseService database;
  LoggerService(this.database);
  void log(String msg) => print('LOG: $msg');
}

@Service(scope: ServiceScope.singleton)
class EmailService {
  final LoggerService logger;
  EmailService(this.logger);
  void send(String to) => print('Email sent to $to');
}

@Service(scope: ServiceScope.transient)
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

@Service(scope: ServiceScope.scoped)
class RequestContextService {
  final String requestId;
  RequestContextService(this.requestId);
  void track(String action) => print('[$requestId] $action');
}

/// Sistema automático de registro de servicios
class AutoServiceRegistrar {
  final ServiceLocator serviceLocator;

  AutoServiceRegistrar(this.serviceLocator);

  /// Simula el escaneo automático de clases con @Service
  /// En tu framework real, esto usaría reflection o code generation
  void registerAllServices() {
    print('🔍 Escaneando servicios automáticamente...');

    // Simular descubrimiento automático de servicios
    final discoveredServices = [
      // El orden está mezclado intencionalmente - simula descubrimiento automático
      _ServiceDefinition<UserService>(
        type: UserService,
        scope: ServiceScope.transient,
        factory: (locator) => UserService(
          locator.get<EmailService>(),
          locator.get<DatabaseService>(),
        ),
      ),

      _ServiceDefinition<RequestContextService>(
        type: RequestContextService,
        scope: ServiceScope.scoped,
        factory: (locator) => RequestContextService(
          'req-${DateTime.now().millisecondsSinceEpoch}',
        ),
      ),

      _ServiceDefinition<EmailService>(
        type: EmailService,
        scope: ServiceScope.singleton,
        factory: (locator) => EmailService(locator.get<LoggerService>()),
      ),

      _ServiceDefinition<DatabaseService>(
        type: DatabaseService,
        scope: ServiceScope.singleton,
        factory: (locator) => DatabaseService(),
      ),

      _ServiceDefinition<LoggerService>(
        type: LoggerService,
        scope: ServiceScope.singleton,
        factory: (locator) => LoggerService(locator.get<DatabaseService>()),
      ),
    ];

    print('✅ Descubiertos ${discoveredServices.length} servicios');
    print('📋 Servicios encontrados:');
    for (final service in discoveredServices) {
      print('   - ${service.type} (${service.scope})');
    }

    // Registrar todos automáticamente usando los métodos Auto
    print('\n🔧 Registrando servicios automáticamente...');

    for (final service in discoveredServices) {
      _registerService(service);
    }

    print('✅ Registro automático completado');

    // Validar dependencias automáticamente
    print('\n🔍 Validando dependencias automáticamente...');
    final errors = serviceLocator.validateDependencies();

    if (errors.isEmpty) {
      print('✅ Todas las dependencias son válidas');
    } else {
      print('❌ Errores de dependencias detectados:');
      for (final error in errors) {
        print('   - $error');
      }
      throw ServiceConfigurationException(
        'Auto-registration failed: ${errors.join(', ')}',
      );
    }
  }

  /// Registra un servicio usando el método apropiado según su scope
  void _registerService<T>(_ServiceDefinition<T> service) {
    switch (service.scope) {
      case ServiceScope.singleton:
        serviceLocator.registerSingletonAuto<T>(service.factory);
        print('   ✅ Registered singleton: ${service.type}');
        break;
      case ServiceScope.transient:
        serviceLocator.registerTransientAuto<T>(service.factory);
        print('   ✅ Registered transient: ${service.type}');
        break;
      case ServiceScope.scoped:
        serviceLocator.registerScopedAuto<T>(service.factory);
        print('   ✅ Registered scoped: ${service.type}');
        break;
    }
  }

  /// Alternativa: Usando bulk registration
  void registerAllServicesBulk() {
    print('🔍 Registro en lote automático...');

    final registrations = [
      ServiceRegistration<UserService>(
        serviceType: UserService,
        scope: ServiceScope.transient,
        factory: (locator) => UserService(
          locator.get<EmailService>(),
          locator.get<DatabaseService>(),
        ),
      ),

      ServiceRegistration<EmailService>(
        serviceType: EmailService,
        scope: ServiceScope.singleton,
        factory: (locator) => EmailService(locator.get<LoggerService>()),
      ),

      ServiceRegistration<LoggerService>(
        serviceType: LoggerService,
        scope: ServiceScope.singleton,
        factory: (locator) => LoggerService(locator.get<DatabaseService>()),
      ),

      ServiceRegistration<DatabaseService>(
        serviceType: DatabaseService,
        scope: ServiceScope.singleton,
        factory: (locator) => DatabaseService(),
      ),

      ServiceRegistration<RequestContextService>(
        serviceType: RequestContextService,
        scope: ServiceScope.scoped,
        factory: (locator) => RequestContextService(
          'bulk-req-${DateTime.now().millisecondsSinceEpoch}',
        ),
      ),
    ];

    print('📦 Registrando ${registrations.length} servicios en lote...');
    serviceLocator.registerBulk(registrations);

    // Validar
    final errors = serviceLocator.validateDependencies();
    if (errors.isNotEmpty) {
      throw ServiceConfigurationException(
        'Bulk registration failed: ${errors.join(', ')}',
      );
    }

    print('✅ Registro en lote completado y validado');
  }
}

/// Clase auxiliar para definir servicios descubiertos
class _ServiceDefinition<T> {
  final Type type;
  final ServiceScope scope;
  final T Function(ServiceLocator locator) factory;

  _ServiceDefinition({
    required this.type,
    required this.scope,
    required this.factory,
  });
}

/// Excepción para errores de configuración de servicios
class ServiceConfigurationException implements Exception {
  final String message;
  ServiceConfigurationException(this.message);

  @override
  String toString() => 'ServiceConfigurationException: $message';
}

void main() {
  print('=== Sistema de Registro Automático de Servicios ===\n');

  final serviceLocator = ServiceLocator.instance;
  final registrar = AutoServiceRegistrar(serviceLocator);

  // Limpiar state anterior
  serviceLocator.clear();

  print('🚀 Demo 1: Registro Individual Automático');
  demonstrateAutoRegistration(registrar);

  print('\n' + '=' * 50 + '\n');

  serviceLocator.clear();
  print('🚀 Demo 2: Registro en Lote');
  demonstrateBulkRegistration(registrar);

  print('\n' + '=' * 50 + '\n');

  print('🚀 Demo 3: Uso Real del Sistema');
  demonstrateRealUsage();
}

void demonstrateAutoRegistration(AutoServiceRegistrar registrar) {
  try {
    // El registrar encuentra y registra servicios automáticamente
    registrar.registerAllServices();

    print('\n🧪 Probando servicios registrados automáticamente...');

    // Usar servicios singleton
    final db = ServiceLocator.instance.get<DatabaseService>();
    db.connect();

    final logger = ServiceLocator.instance.get<LoggerService>();
    logger.log('Auto-registration works!');

    final email = ServiceLocator.instance.get<EmailService>();
    email.send('auto@example.com');

    // Usar servicio transient
    final user1 = ServiceLocator.instance.get<UserService>();
    final user2 = ServiceLocator.instance.get<UserService>();
    print('Transient services are different: ${!identical(user1, user2)}');

    user1.createUser('user1@example.com');

    // Usar servicio scoped
    ServiceLocator.instance.beginScope('auto-request-1');
    final context1 = ServiceLocator.instance.get<RequestContextService>();
    final context2 = ServiceLocator.instance.get<RequestContextService>();
    print(
      'Scoped services are same in scope: ${identical(context1, context2)}',
    );

    context1.track('login');
    ServiceLocator.instance.endScope();
  } catch (e) {
    print('❌ Error en registro automático: $e');
  }
}

void demonstrateBulkRegistration(AutoServiceRegistrar registrar) {
  try {
    registrar.registerAllServicesBulk();

    print('\n🧪 Probando servicios registrados en lote...');

    final userService = ServiceLocator.instance.get<UserService>();
    userService.createUser('bulk@example.com');

    print('✅ Registro en lote funciona perfectamente');
  } catch (e) {
    print('❌ Error en registro en lote: $e');
  }
}

void demonstrateRealUsage() {
  print('💼 Simulación de Uso Real en Diana Framework');

  // Simular el bootstrap de tu framework
  final serviceLocator = ServiceLocator.instance;
  serviceLocator.clear();

  print('1. 🔍 Framework escanea automáticamente las clases...');
  print('2. 🔧 Encuentra servicios con @Service...');
  print('3. 📝 Registra automáticamente sin importar el orden...');

  final registrar = AutoServiceRegistrar(serviceLocator);
  registrar.registerAllServices();

  print('4. ✅ Framework listo para usar');

  // Simular request web
  print('\n📡 Simulando request HTTP...');
  serviceLocator.beginScope('http-request-123');

  try {
    final userService = serviceLocator.get<UserService>();
    final context = serviceLocator.get<RequestContextService>();

    context.track('request started');
    userService.createUser('realuser@example.com');
    context.track('user created');
  } finally {
    serviceLocator.endScope();
    print('🏁 Request completado, scope limpiado');
  }

  print('\n🎯 Ventajas del Sistema Automático:');
  print('   ✅ No necesitas conocer el orden de dependencias');
  print('   ✅ Registro completamente automático');
  print('   ✅ Validación automática de dependencias');
  print('   ✅ Manejo automático de scopes');
  print('   ✅ Detección de dependencias circulares');
  print('   ✅ Compatibilidad con todos los tipos de scope');
}
