import 'middleware.dart';
import '../http/handler.dart';
import '../http/request.dart';
import '../http/response.dart';

/// CORS (Cross-Origin Resource Sharing) middleware for Diana framework
///
/// This middleware handles CORS preflight requests and adds appropriate
/// CORS headers to responses to enable cross-origin requests from web browsers.
class CorsMiddleware extends DianaMiddleware {
  /// Allowed origins. Use '*' for all origins or specify specific domains
  final List<String> allowedOrigins;

  /// Allowed HTTP methods
  final List<String> allowedMethods;

  /// Allowed request headers
  final List<String> allowedHeaders;

  /// Headers that the client can access
  final List<String> exposedHeaders;

  /// Whether to allow credentials (cookies, authorization headers)
  final bool allowCredentials;

  /// Maximum age for preflight cache (in seconds)
  final int? maxAge;

  /// Whether to handle preflight requests automatically
  final bool handlePreflightRequests;

  CorsMiddleware({
    List<String>? allowedOrigins,
    List<String>? allowedMethods,
    List<String>? allowedHeaders,
    List<String>? exposedHeaders,
    this.allowCredentials = false,
    this.maxAge,
    this.handlePreflightRequests = true,
  }) : allowedOrigins = allowedOrigins ?? ['*'],
       allowedMethods =
           allowedMethods ??
           ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS', 'HEAD', 'PATCH'],
       allowedHeaders =
           allowedHeaders ??
           ['Content-Type', 'Authorization', 'X-Requested-With'],
       exposedHeaders = exposedHeaders ?? [];

  @override
  Future<DianaResponse> handle(DianaRequest request, DianaHandler next) async {
    final origin = request.header('origin');

    // Check if origin is allowed
    if (!_isOriginAllowed(origin)) {
      // If origin is not allowed, continue without CORS headers
      return await next(request);
    }

    // Handle preflight OPTIONS request
    if (handlePreflightRequests && request.method == 'OPTIONS') {
      return _handlePreflightRequest(request, origin);
    }

    // Process normal request and add CORS headers
    final response = await next(request);
    return _addCorsHeaders(response, origin, request);
  }

  /// Handles CORS preflight requests (OPTIONS method)
  DianaResponse _handlePreflightRequest(DianaRequest request, String? origin) {
    final requestMethod = request.header('access-control-request-method');
    final requestHeaders = request.header('access-control-request-headers');

    // Check if requested method is allowed
    if (requestMethod != null && !_isMethodAllowed(requestMethod)) {
      return DianaResponse(403, body: 'Method not allowed by CORS policy');
    }

    // Check if requested headers are allowed
    if (requestHeaders != null && !_areHeadersAllowed(requestHeaders)) {
      return DianaResponse(403, body: 'Headers not allowed by CORS policy');
    }

    final headers = <String, String>{};

    // Add origin header
    if (origin != null) {
      headers['Access-Control-Allow-Origin'] = _getAllowOriginHeader(origin);
    }

    // Add allowed methods
    headers['Access-Control-Allow-Methods'] = allowedMethods.join(', ');

    // Add allowed headers
    if (allowedHeaders.isNotEmpty) {
      headers['Access-Control-Allow-Headers'] = allowedHeaders.join(', ');
    }

    // Add credentials header if needed
    if (allowCredentials) {
      headers['Access-Control-Allow-Credentials'] = 'true';
    }

    // Add max age if specified
    if (maxAge != null) {
      headers['Access-Control-Max-Age'] = maxAge.toString();
    }

    // Add vary header to indicate response varies by origin
    headers['Vary'] =
        'Origin, Access-Control-Request-Method, Access-Control-Request-Headers';

    return DianaResponse(204, headers: headers);
  }

  /// Adds CORS headers to a regular response
  DianaResponse _addCorsHeaders(
    DianaResponse response,
    String? origin,
    DianaRequest request,
  ) {
    final corsHeaders = <String, String>{};

    // Add origin header
    if (origin != null) {
      corsHeaders['Access-Control-Allow-Origin'] = _getAllowOriginHeader(
        origin,
      );
    }

    // Add exposed headers
    if (exposedHeaders.isNotEmpty) {
      corsHeaders['Access-Control-Expose-Headers'] = exposedHeaders.join(', ');
    }

    // Add credentials header if needed
    if (allowCredentials) {
      corsHeaders['Access-Control-Allow-Credentials'] = 'true';
    }

    // Add vary header
    corsHeaders['Vary'] = 'Origin';

    // Create new response with CORS headers added
    // We need to preserve the original response body and status
    return DianaResponse.fromShelf(
      response.shelfResponse.change(
        headers: {...response.headers, ...corsHeaders},
      ),
    );
  }

  /// Checks if the origin is allowed
  bool _isOriginAllowed(String? origin) {
    if (origin == null)
      return true; // Same-origin requests don't have Origin header
    if (allowedOrigins.contains('*')) return true;
    return allowedOrigins.contains(origin);
  }

  /// Checks if the HTTP method is allowed
  bool _isMethodAllowed(String method) {
    return allowedMethods.contains(method.toUpperCase());
  }

  /// Checks if the requested headers are allowed
  bool _areHeadersAllowed(String requestHeaders) {
    final headers = requestHeaders
        .split(',')
        .map((h) => h.trim().toLowerCase())
        .toList();

    final allowedLower = allowedHeaders.map((h) => h.toLowerCase()).toList();

    return headers.every((header) => allowedLower.contains(header));
  }

  /// Gets the appropriate Allow-Origin header value
  String _getAllowOriginHeader(String origin) {
    if (allowedOrigins.contains('*') && !allowCredentials) {
      return '*';
    }
    return origin;
  }
}

/// Preset CORS configurations for common use cases
class CorsPresets {
  /// Very permissive CORS - allows everything (development only!)
  static CorsMiddleware permissive() {
    return CorsMiddleware(
      allowedOrigins: ['*'],
      allowedMethods: [
        'GET',
        'POST',
        'PUT',
        'DELETE',
        'OPTIONS',
        'HEAD',
        'PATCH',
      ],
      allowedHeaders: ['*'],
      allowCredentials: false,
    );
  }

  /// Restrictive CORS - only allows same origin (default behavior)
  static CorsMiddleware restrictive() {
    return CorsMiddleware(allowedOrigins: [], handlePreflightRequests: false);
  }

  /// API CORS - suitable for REST APIs
  static CorsMiddleware api({
    required List<String> allowedOrigins,
    bool allowCredentials = false,
  }) {
    return CorsMiddleware(
      allowedOrigins: allowedOrigins,
      allowedMethods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
      allowedHeaders: ['Content-Type', 'Authorization'],
      allowCredentials: allowCredentials,
      maxAge: 86400, // 24 hours
    );
  }

  /// Development CORS - allows localhost origins
  static CorsMiddleware development() {
    return CorsMiddleware(
      allowedOrigins: [
        'http://localhost:3000',
        'http://localhost:8080',
        'http://localhost:5173', // Vite default
        'http://127.0.0.1:3000',
        'http://127.0.0.1:8080',
        'http://127.0.0.1:5173',
      ],
      allowedMethods: [
        'GET',
        'POST',
        'PUT',
        'DELETE',
        'OPTIONS',
        'HEAD',
        'PATCH',
      ],
      allowedHeaders: ['Content-Type', 'Authorization', 'X-Requested-With'],
      allowCredentials: true,
      maxAge: 3600, // 1 hour
    );
  }
}
