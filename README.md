# Diana Framework

Diana es un framework web moderno para Dart que proporciona una arquitectura robusta para el desarrollo de APIs REST y aplicaciones web.

## Características Principales

- **Inyección de Dependencias**: Sistema automático de service locator
- **Middleware**: Sistema de middleware flexible y extensible
- **Guards**: Sistema de autenticación y autorización robusto
- **Anotaciones**: Decoradores para controllers, servicios y rutas
- **HTTP**: Abstracción completa de requests y responses
- **Modular**: Arquitectura basada en componentes

## Instalación

Añade Diana a tu `pubspec.yaml`:

```yaml
dependencies:
  diana: ^1.0.0
```

## Uso Básico

### Controller Simple

```dart
import 'package:diana/diana.dart';

@Controller('/api/users')
class UserController {
  @Get('/')
  Future<DianaResponse> getUsers() async {
    return DianaResponse.json(['user1', 'user2']);
  }
  
  @Post('/')
  Future<DianaResponse> createUser(@Body() Map<String, dynamic> user) async {
    // Lógica para crear usuario
    return DianaResponse.json({'id': 1, ...user});
  }
}
```

### Middleware

```dart
// Middleware personalizado
class LoggingMiddleware extends DianaMiddleware {
  @override
  Future<DianaResponse> handle(DianaRequest request, DianaHandler next) async {
    print('Request: ${request.method} ${request.uri}');
    final response = await next(request);
    print('Response: ${response.statusCode}');
    return response;
  }
}
```

### Guards - Autenticación y Autorización

Diana incluye un sistema robusto de Guards basado en anotaciones para manejar autenticación, autorización y control de acceso.

```dart
// Guard personalizado con inyección de dependencias
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

// Controller con Guards a nivel de clase
@Guard(RoleGuard, {'role': 'admin'})
@Controller('/admin')
class AdminController {
  
  @Get('/users')
  Future<DianaResponse> getUsers() async {
    return DianaResponse.json(['user1', 'user2']);
  }
  
  // Guard adicional a nivel de método
  @Guard(AuthGuard, {'secretKey': 'super-secret'})
  @Post('/users')
  Future<DianaResponse> createUser(@Body() Map<String, dynamic> user) async {
    return DianaResponse.json({'id': 1, ...user});
  }
}
```

#### Guards Incluidos

```dart
// Guard de autenticación
@Injectable()
class AuthGuard extends DianaGuard {
  @override
  Future<GuardResult> canActivate(DianaRequest request, [Map<String, dynamic>? config]) async {
    // Lógica de autenticación
  }
}

// Guard de autorización por roles
@Injectable()
class RoleGuard extends DianaGuard {
  @override
  Future<GuardResult> canActivate(DianaRequest request, [Map<String, dynamic>? config]) async {
    // Lógica de autorización
  }
}

// Guard de rate limiting
@Injectable()
class RateLimitGuard extends DianaGuard {
  @override
  Future<GuardResult> canActivate(DianaRequest request, [Map<String, dynamic>? config]) async {
    // Lógica de rate limiting
  }
}
```

#### Registro de Guards

```dart
void main() async {
  // Registrar guards en el sistema
  GuardRegistry.registerCommonGuards();
  
  // Registrar guards personalizados
  GuardProcessor.registerGuardFactory<CustomGuard>(() => CustomGuard());
  
  final app = Diana();
  await app.listen();
}
```

## Documentación

- [**Guards - Guía Completa**](GUARDS.md) - Documentación detallada del sistema de Guards
- [**Guards - Guía Rápida**](GUARDS_QUICK_START.md) - Referencia rápida para Guards
- [**Ejemplos**](example/) - Ejemplos prácticos de uso

## Ejemplos

```dart
// Servidor básico con Diana
void main() async {
  // Registrar guards
  GuardRegistry.registerCommonGuards();
  
  final app = Diana();
  
  // En el futuro, los controllers serán registrados automáticamente
  // con sus guards procesados a partir de las anotaciones
  
  await app.listen(port: 3000);
}

// Ejemplo de controller con guards
@Guard(AuthGuard, {'secretKey': 'my-secret'})
@Controller('/api')
class ApiController {
  
  @Get('/profile')
  Future<DianaResponse> getProfile(DianaRequest req) async {
    final user = req.getContext<Map<String, Object?>>('user');
    return DianaResponse.json({'user': user});
  }
  
  @Guard(RoleGuard, {'role': 'admin'})
  @Get('/admin/users')
  Future<DianaResponse> getUsers() async {
    return DianaResponse.json(['admin', 'user1', 'user2']);
  }
}
```

## Características Avanzadas

### Sistema de Guards
- **Guards basados en anotaciones**: `@Guard(GuardType, config)`
- **Inyección de dependencias**: Guards pueden usar DI automáticamente
- **AuthGuard**: Autenticación basada en tokens
- **RoleGuard**: Autorización por roles
- **RateLimitGuard**: Limitación de tasa por IP/usuario
- **Guards Personalizados**: Crea tus propios guards con `@Injectable()`
- **Configuración**: Configura guards mediante parámetros en anotaciones

### Middleware
- Sistema de middleware compatible con Shelf
- Middleware personalizado fácil de crear
- Integración perfecta con Guards

### Inyección de Dependencias
- Service Locator automático
- Anotaciones `@Injectable` y `@Service`
- Gestión automática del ciclo de vida

## Contribuir

Las contribuciones son bienvenidas. Por favor:

1. Fork el proyecto
2. Crea una rama para tu feature
3. Añade tests para nuevas funcionalidades
4. Asegúrate de que todos los tests pasen
5. Envía un Pull Request

## Licencia

Este proyecto está bajo la licencia MIT. Ver el archivo LICENSE para más detalles.
