import '../lib/src/core/middleware/cors_middleware.dart';
import '../lib/src/core/middleware/middleware.dart';
import '../lib/src/core/http/request.dart';
import '../lib/src/core/http/response.dart';
import '../lib/src/core/http/handler.dart';

void main() {
  print('=== Diana CORS Middleware Examples ===\n');

  // Ejemplo 1: CORS Permisivo (desarrollo)
  print('1. CORS Permisivo (solo para desarrollo):');
  final permissiveCors = CorsPresets.permissive();
  print('   - Permite todos los orígenes (*)');
  print('   - Permite todos los métodos HTTP');
  print('   - No permite credenciales\n');

  // Ejemplo 2: CORS para API en producción
  print('2. CORS para API (producción):');
  final apiCors = CorsPresets.api(
    allowedOrigins: [
      'https://myapp.com',
      'https://www.myapp.com',
      'https://admin.myapp.com',
    ],
    allowCredentials: true,
  );
  print('   - Solo orígenes específicos');
  print('   - Métodos REST estándar');
  print('   - Permite credenciales\n');

  // Ejemplo 3: CORS personalizado
  print('3. CORS Personalizado:');
  final customCors = CorsMiddleware(
    allowedOrigins: ['https://trusted-domain.com'],
    allowedMethods: ['GET', 'POST'],
    allowedHeaders: ['Content-Type', 'X-API-Key'],
    exposedHeaders: ['X-Total-Count', 'X-Page-Count'],
    allowCredentials: true,
    maxAge: 3600, // 1 hora
  );
  print('   - Configuración muy específica');
  print('   - Headers expuestos personalizados');
  print('   - Cache de preflight de 1 hora\n');

  // Ejemplo 4: CORS para desarrollo local
  print('4. CORS para Desarrollo:');
  final devCors = CorsPresets.development();
  print('   - Permite puertos localhost comunes');
  print('   - Ideal para desarrollo frontend\n');

  print('=== Simulación de Requests ===\n');

  // Simular diferentes tipos de requests
  _simulateRequests();
}

void _simulateRequests() {
  // Configurar middleware
  final cors = CorsMiddleware(
    allowedOrigins: ['https://myapp.com', 'http://localhost:3000'],
    allowedMethods: ['GET', 'POST', 'PUT', 'DELETE'],
    allowedHeaders: ['Content-Type', 'Authorization'],
    allowCredentials: true,
    maxAge: 86400,
  );

  print('📋 Configuración CORS:');
  print('   Orígenes: https://myapp.com, http://localhost:3000');
  print('   Métodos: GET, POST, PUT, DELETE');
  print('   Headers: Content-Type, Authorization');
  print('   Credenciales: Sí\n');

  // Simular request preflight (OPTIONS)
  print('🔍 1. Request Preflight (OPTIONS):');
  print('   Origin: https://myapp.com');
  print('   Method: OPTIONS');
  print('   Access-Control-Request-Method: POST');
  print('   Access-Control-Request-Headers: Content-Type');
  print('   ✅ Respuesta: 204 No Content con headers CORS\n');

  // Simular request normal
  print('🔍 2. Request Normal (POST):');
  print('   Origin: https://myapp.com');
  print('   Method: POST');
  print('   ✅ Respuesta: Headers CORS añadidos a la respuesta\n');

  // Simular request de origen no permitido
  print('🔍 3. Request de Origen No Permitido:');
  print('   Origin: https://malicious-site.com');
  print('   Method: GET');
  print('   ❌ Respuesta: Sin headers CORS (bloqueado por browser)\n');

  // Simular request sin origen (same-origin)
  print('🔍 4. Request Same-Origin:');
  print('   Origin: (ninguno)');
  print('   Method: GET');
  print('   ✅ Respuesta: Permitido (mismo origen)\n');

  print('=== Headers CORS Típicos ===\n');

  print('📤 Response Headers para Preflight:');
  print('   Access-Control-Allow-Origin: https://myapp.com');
  print('   Access-Control-Allow-Methods: GET, POST, PUT, DELETE');
  print('   Access-Control-Allow-Headers: Content-Type, Authorization');
  print('   Access-Control-Allow-Credentials: true');
  print('   Access-Control-Max-Age: 86400');
  print(
    '   Vary: Origin, Access-Control-Request-Method, Access-Control-Request-Headers\n',
  );

  print('📤 Response Headers para Request Normal:');
  print('   Access-Control-Allow-Origin: https://myapp.com');
  print('   Access-Control-Allow-Credentials: true');
  print('   Vary: Origin\n');

  print('=== Casos de Uso Comunes ===\n');

  print('🌐 Frontend + API en diferentes dominios:');
  print('   Frontend: https://myapp.com');
  print('   API: https://api.myapp.com');
  print('   Solución: CORS en API permite myapp.com\n');

  print('💻 Desarrollo local:');
  print('   Frontend: http://localhost:3000 (React/Vue/Angular)');
  print('   API: http://localhost:8080 (Diana)');
  print('   Solución: CorsPresets.development()\n');

  print('📱 App móvil + API:');
  print('   App: Cualquier origen');
  print('   API: https://api.myapp.com');
  print('   Solución: CORS permisivo sin credenciales\n');

  print('🔒 Admin panel con autenticación:');
  print('   Admin: https://admin.myapp.com');
  print('   API: https://api.myapp.com');
  print('   Solución: CORS restrictivo con credenciales\n');
}

/// Ejemplo de uso en una aplicación Diana real
void exampleUsage() {
  // En tu aplicación Diana, registrarías el middleware así:

  // Para desarrollo
  final devCors = CorsPresets.development();

  // Para producción con orígenes específicos
  final prodCors = CorsPresets.api(
    allowedOrigins: ['https://myapp.com', 'https://www.myapp.com'],
    allowCredentials: true,
  );

  // Para casos muy específicos
  final customCors = CorsMiddleware(
    allowedOrigins: ['https://trusted-partner.com'],
    allowedMethods: ['GET', 'POST'],
    allowedHeaders: ['Content-Type', 'X-API-Key', 'Authorization'],
    exposedHeaders: ['X-Rate-Limit-Remaining', 'X-Rate-Limit-Reset'],
    allowCredentials: true,
    maxAge: 7200, // 2 horas
  );

  print('Middleware registrado correctamente para Diana framework!');
}
