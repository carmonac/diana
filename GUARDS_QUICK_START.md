# Diana Guards - Guía Rápida

## Instalación y Configuración

1. Los Guards ya están incluidos en el framework Diana
2. Importa el paquete principal: `import 'package:diana/diana.dart';`

## Uso Básico

### Autenticación Simple

```dart
// Ruta protegida con autenticación
app.get('/protected', handler, middlewares: [
  Guards.auth(secretKey: 'mi-clave-secreta')
]);
```

### Autorización por Roles

```dart
// Solo administradores
app.get('/admin', handler, middlewares: [
  Guards.authAndRoles(['admin'])
]);

// Múltiples roles permitidos
app.get('/moderator', handler, middlewares: [
  Guards.authAndRoles(['admin', 'moderator'])
]);
```

### Rate Limiting

```dart
// Máximo 100 requests por hora
app.get('/api/data', handler, middlewares: [
  Guards.rateLimit(
    maxRequests: 100,
    timeWindow: Duration(hours: 1),
  )
]);
```

## Headers Requeridos

### Para Autenticación

```http
Authorization: Bearer tu-token-aqui
# o simplemente
Authorization: tu-token-aqui
```

### Para Custom Headers

```dart
Guards.auth(tokenHeaderName: 'x-api-key')
```

```http
X-API-Key: tu-token-aqui
```

## Patrones Comunes

### API REST Básica

```dart
// Rutas públicas
app.get('/health', healthHandler);
app.post('/login', loginHandler);

// Rutas autenticadas
app.get('/profile', profileHandler, middlewares: [
  Guards.auth()
]);

// Rutas de administrador
app.delete('/users/:id', deleteUserHandler, middlewares: [
  Guards.authAndRoles(['admin'])
]);
```

### API con Rate Limiting

```dart
// API pública con limite
app.get('/public-api', handler, middlewares: [
  Guards.rateLimit(maxRequests: 1000, timeWindow: Duration(hours: 1))
]);

// API privada con limite más bajo
app.get('/private-api', handler, middlewares: [
  Guards.auth(),
  Guards.rateLimit(maxRequests: 100, timeWindow: Duration(hours: 1))
]);
```

### Múltiples Niveles de Seguridad

```dart
app.post('/admin/sensitive', handler, middlewares: [
  Guards.combine([
    AuthGuard(),
    RoleGuard(requiredRoles: ['admin']),
    RateLimitGuard(maxRequests: 10, timeWindow: Duration(minutes: 1)),
    IPWhitelistGuard(['192.168.1.100']),
  ])
]);
```

## Acceso a Datos del Contexto

```dart
app.get('/dashboard', (req) async {
  // Datos añadidos por AuthGuard
  final user = req.getContext<Map<String, Object?>>('user');
  
  // Datos añadidos por custom guards
  final permissions = req.getContext<List<String>>('permissions');
  final clientIP = req.getContext<String>('clientIP');
  
  return DianaResponse.json({
    'user': user?['id'],
    'permissions': permissions,
    'clientIP': clientIP,
  });
});
```

## Guards Personalizados

### Guard Simple

```dart
class MaintenanceGuard extends DianaGuard {
  final bool maintenanceMode;
  
  MaintenanceGuard({this.maintenanceMode = false});
  
  @override
  Future<GuardResult> canActivate(DianaRequest request) async {
    if (maintenanceMode) {
      return GuardResult.deny(
        DianaResponse(503, body: 'Service under maintenance')
      );
    }
    return GuardResult.allow();
  }
}
```

### Guard con Configuración

```dart
class GeoLocationGuard extends DianaGuard {
  final List<String> allowedCountries;
  
  GeoLocationGuard(this.allowedCountries);
  
  @override
  Future<GuardResult> canActivate(DianaRequest request) async {
    final country = await getCountryFromIP(request);
    
    if (!allowedCountries.contains(country)) {
      return GuardResult.forbidden('Access not allowed from $country');
    }
    
    return GuardResult.allow(contextData: {'country': country});
  }
}
```

## Códigos de Estado HTTP

| Guard Result | Código HTTP | Descripción |
|--------------|-------------|-------------|
| `GuardResult.allow()` | Continúa | Acceso permitido |
| `GuardResult.unauthorized()` | 401 | No autenticado |
| `GuardResult.forbidden()` | 403 | Sin permisos |
| `GuardResult.deny(response)` | Custom | Respuesta personalizada |

## Debugging

### Logs de Guards

```dart
class LoggingGuard extends DianaGuard {
  final DianaGuard innerGuard;
  
  LoggingGuard(this.innerGuard);
  
  @override
  Future<GuardResult> canActivate(DianaRequest request) async {
    print('Guard ${innerGuard.runtimeType} executing...');
    final result = await innerGuard.canActivate(request);
    print('Guard ${innerGuard.runtimeType}: ${result.canActivate}');
    return result;
  }
}
```

### Uso del Logging Guard

```dart
Guards.combine([
  LoggingGuard(AuthGuard()),
  LoggingGuard(RoleGuard(requiredRoles: ['admin'])),
]);
```

## Mejores Prácticas

1. **Orden de Guards**: Coloca guards rápidos primero (IP, cache) antes que guards costosos (DB lookups)
2. **Cache**: Usa cache para validaciones costosas de tokens
3. **Timeouts**: Añade timeouts a guards que hacen llamadas externas
4. **Errores**: Proporciona mensajes de error claros pero no expongas información sensible
5. **Testing**: Crea mocks para guards en tests unitarios

## Ejemplos Completos

Ver archivos de ejemplo en el proyecto:
- `example/guards_example.dart` - Ejemplos básicos
- `example/guards_integration_example.dart` - Integración completa
- `test/guards_test.dart` - Tests unitarios
