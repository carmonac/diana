# Diana Guards - Sistema Basado en Anotaciones

Los Guards en Diana son un sistema poderoso para controlar el acceso a rutas mediante anotaciones y con soporte completo para inyección de dependencias.

## ¿Qué son los Guards?

Los Guards son clases que implementan `DianaGuard` y determinan si una request debe continuar o ser bloqueada. Se aplican mediante anotaciones y se integran perfectamente con el sistema de inyección de dependencias.

## Características Principales

- **Basados en anotaciones**: `@Guard(GuardType, config)`
- **Inyección de dependencias**: Automática con `@Injectable()`
- **Configurables**: Parámetros definidos en la anotación
- **Composables**: Múltiples guards por controller/método
- **Contextualización**: Guards pueden añadir datos al contexto

## Uso Básico

### Creando un Guard

```dart
@Injectable()
class RoleGuard extends DianaGuard {
  Logger logger;
  
  RoleGuard(this.logger); // Inyección automática

  @override
  Future<GuardResult> canActivate(DianaRequest request, [Map<String, dynamic>? config]) async {
    final requiredRole = config?['role'] ?? 'user';
    logger.log('Verificando rol: $requiredRole');
    
    final user = request.getContext<Map<String, Object?>>('user');
    final userRoles = user?['roles'] as List<String>? ?? [];
    
    if (!userRoles.contains(requiredRole)) {
      return GuardResult.forbidden('Rol requerido: $requiredRole');
    }
    
    return GuardResult.allow();
  }
}
```

### Aplicando Guards con Anotaciones

```dart
// Guard a nivel de controller
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

## Guards Incluidos

### 1. AuthGuard - Autenticación

```dart
@Injectable()
class AuthGuard extends DianaGuard {
  @override
  Future<GuardResult> canActivate(DianaRequest request, [Map<String, dynamic>? config]) async {
    final secretKey = config?['secretKey'];
    final tokenHeaderName = config?['tokenHeaderName'] ?? 'authorization';
    
    final token = request.header(tokenHeaderName);
    
    if (token == null || !_validateToken(token, secretKey)) {
      return GuardResult.unauthorized('Token de autenticación requerido');
    }
    
    final userInfo = await _extractUserInfo(token);
    return GuardResult.allow(contextData: {'user': userInfo});
  }
}

// Uso
@Guard(AuthGuard, {
  'secretKey': 'mi-clave-secreta',
  'tokenHeaderName': 'authorization'
})
```

### 2. RoleGuard - Autorización por Roles

```dart
@Injectable()
class RoleGuard extends DianaGuard {
  @override
  Future<GuardResult> canActivate(DianaRequest request, [Map<String, dynamic>? config]) async {
    final requiredRole = config?['role'];
    final user = request.getContext<Map<String, Object?>>('user');
    
    if (user == null) {
      return GuardResult.unauthorized('Usuario no autenticado');
    }
    
    final userRoles = user['roles'] as List<String>? ?? [];
    
    if (!userRoles.contains(requiredRole)) {
      return GuardResult.forbidden('Rol requerido: $requiredRole');
    }
    
    return GuardResult.allow();
  }
}

// Uso
@Guard(RoleGuard, {'role': 'admin'})
// o para múltiples roles
@Guard(RoleGuard, {'roles': ['admin', 'moderator']})
```

### 3. RateLimitGuard - Limitación de Tasa

```dart
@Injectable()
class RateLimitGuard extends DianaGuard {
  static final Map<String, List<DateTime>> _requestHistory = {};
  
  @override
  Future<GuardResult> canActivate(DianaRequest request, [Map<String, dynamic>? config]) async {
    final maxRequests = config?['maxRequests'] ?? 100;
    final timeWindowMinutes = config?['timeWindowMinutes'] ?? 60;
    
    final clientId = _getClientIdentifier(request);
    
    if (_isRateLimited(clientId, maxRequests, timeWindowMinutes)) {
      return GuardResult.deny(
        DianaResponse(429, body: 'Rate limit exceeded')
      );
    }
    
    return GuardResult.allow();
  }
}

// Uso
@Guard(RateLimitGuard, {
  'maxRequests': 100,
  'timeWindowMinutes': 60
})
```

## Múltiples Guards

### Con Múltiples Anotaciones

```dart
@Guard(AuthGuard, {'secretKey': 'secret'})
@Guard(RoleGuard, {'role': 'admin'})
@Controller('/secure')
class SecureController { ... }
```

### Con Anotación Grupal

```dart
@GuardsAnnotation([
  GuardConfig(AuthGuard, {'secretKey': 'secret'}),
  GuardConfig(RoleGuard, {'role': 'admin'}),
  GuardConfig(RateLimitGuard, {'maxRequests': 10}),
])
@Controller('/ultra-secure')
class UltraSecureController { ... }
```

## Configuración del Sistema

### Registro de Guards

```dart
void main() async {
  // Registrar guards incluidos
  GuardRegistry.registerCommonGuards();
  
  // Registrar guards personalizados
  GuardProcessor.registerGuardFactory<CustomGuard>(() => CustomGuard());
  GuardProcessor.registerGuardFactory<TimeBasedGuard>(() => TimeBasedGuard());
  
  final app = Diana();
  await app.listen();
}
```

### Guards Personalizados

```dart
@Injectable()
class IPWhitelistGuard extends DianaGuard {
  NetworkService networkService;
  
  IPWhitelistGuard(this.networkService);
  
  @override
  Future<GuardResult> canActivate(DianaRequest request, [Map<String, dynamic>? config]) async {
    final allowedIPs = config?['allowedIPs'] as List<String>? ?? [];
    final clientIP = networkService.getClientIP(request);
    
    if (!allowedIPs.contains(clientIP)) {
      return GuardResult.forbidden('IP no permitida: $clientIP');
    }
    
    return GuardResult.allow(contextData: {'clientIP': clientIP});
  }
}

// Uso
@Guard(IPWhitelistGuard, {
  'allowedIPs': ['192.168.1.100', '10.0.0.1']
})
```

## Resultados de Guards

```dart
// Permitir acceso
return GuardResult.allow();

// Permitir con datos de contexto
return GuardResult.allow(contextData: {
  'user': userInfo,
  'permissions': ['read', 'write']
});

// Respuestas de error predefinidas
return GuardResult.unauthorized('Token requerido');
return GuardResult.forbidden('Permisos insuficientes');

// Respuesta personalizada
return GuardResult.deny(
  DianaResponse(403, body: 'Acceso denegado por política de empresa')
);
```

## Datos de Contexto

Los Guards pueden añadir datos al contexto que estarán disponibles en los handlers:

```dart
// En el Guard
return GuardResult.allow(contextData: {
  'user': userInfo,
  'permissions': ['read', 'write'],
  'loginTime': DateTime.now(),
});

// En el controller method
@Get('/data')
Future<DianaResponse> getData(DianaRequest req) async {
  final user = req.getContext<Map<String, Object?>>('user');
  final permissions = req.getContext<List<String>>('permissions');
  
  return DianaResponse.json({
    'data': 'some data',
    'user': user?['name'],
    'can_edit': permissions?.contains('write') ?? false,
  });
}
```

## Orden de Ejecución

1. **Guards de clase**: Se ejecutan primero, en el orden declarado
2. **Guards de método**: Se ejecutan después de los de clase
3. **Contexto**: Los datos de contexto se van acumulando entre guards exitosos

```dart
@Guard(AuthGuard)           // 1. Se ejecuta primero
@Guard(RoleGuard)           // 2. Se ejecuta segundo
@Controller('/api')
class ApiController {
  
  @Guard(PermissionGuard)   // 3. Se ejecuta tercero
  @Get('/data')             // 4. Finalmente el handler
  Future<DianaResponse> getData() async { ... }
}
```

## Mejores Prácticas

### 1. Diseño de Guards

```dart
// ✅ Good: Guard específico y reutilizable
@Injectable()
class RequireEmailVerifiedGuard extends DianaGuard {
  UserService userService;
  
  RequireEmailVerifiedGuard(this.userService);
  
  @override
  Future<GuardResult> canActivate(DianaRequest request, [Map<String, dynamic>? config]) async {
    final user = request.getContext<User>('user');
    
    if (!await userService.isEmailVerified(user.id)) {
      return GuardResult.forbidden('Email verification required');
    }
    
    return GuardResult.allow();
  }
}

// ❌ Bad: Guard muy genérico
class GenericBusinessLogicGuard extends DianaGuard { ... }
```

### 2. Configuración

```dart
// ✅ Good: Configuración clara y tipada
@Guard(RoleGuard, {
  'roles': ['admin', 'moderator'],
  'requireAll': false,  // cualquier rol es suficiente
})

// ❌ Bad: Configuración ambigua
@Guard(RoleGuard, {'value': 'admin,moderator'})
```

### 3. Manejo de Errores

```dart
// ✅ Good: Mensajes de error específicos
if (!hasPermission) {
  return GuardResult.forbidden(
    'Se requiere permiso "write" para esta acción'
  );
}

// ❌ Bad: Mensajes genéricos
return GuardResult.forbidden('Access denied');
```

### 4. Performance

```dart
// ✅ Good: Guards rápidos primero
@Guard(RateLimitGuard)      // Rápido
@Guard(AuthGuard)           // Medio
@Guard(DatabasePermissionGuard) // Lento

// ❌ Bad: Guards lentos primero
@Guard(DatabasePermissionGuard)
@Guard(RateLimitGuard)
```

## Integración con Middleware

Los Guards se ejecutan como parte del sistema de middleware, pero están específicamente diseñados para control de acceso:

```dart
// Orden de ejecución típico:
1. Middleware de logging
2. Middleware de CORS
3. Guards (AuthGuard, RoleGuard, etc.)
4. Handler del controller
5. Middleware de respuesta
```

## Debugging y Logging

```dart
@Injectable()
class DebuggableGuard extends DianaGuard {
  Logger logger;
  
  DebuggableGuard(this.logger);
  
  @override
  Future<GuardResult> canActivate(DianaRequest request, [Map<String, dynamic>? config]) async {
    logger.debug('Guard ${runtimeType} executing with config: $config');
    
    try {
      final result = await _performCheck(request, config);
      logger.debug('Guard ${runtimeType} result: ${result.canActivate}');
      return result;
    } catch (e) {
      logger.error('Guard ${runtimeType} failed: $e');
      return GuardResult.deny(DianaResponse.internalServerError());
    }
  }
}
```

El sistema de Guards de Diana proporciona una manera elegante y poderosa de manejar la seguridad y el control de acceso en tu aplicación, manteniendo el código limpio y las responsabilidades bien separadas.
