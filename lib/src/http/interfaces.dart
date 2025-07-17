import 'dart:io';
import '../core/base/base.dart';

abstract class DianaServer {
  Future<void> start(String host, int port);
  Future<void> stop();
  void addRoute(String method, String path, DianaHandler handler);
  void addMiddleware(DianaMiddleware middleware);
}

abstract class DianaRequest {
  String get method;
  Uri get uri;
  String get host;
  DianaRequest change({
    Map<String, Object?>? headers,
    Map<String, Object?>? context,
    String? path,
    Object? body,
  });
  Map<String, String> get headers;
  Map<String, String> get queryParameters;
  Map<String, List<String>> get queryParametersAll;
  Map<String, Object?> get context;
  Future<String> readAsString();
  Future<List<int>> readAsBytes();
  Stream<List<int>> readAsStream();
  T? getContext<T>(String key);
  String? get contentType;
  String? get accept;
  String? header(String name);
  HttpConnectionInfo? connectionInfo();
  DianaRequest copyWith({Map<String, Object?>? context});
}

abstract class DianaResponse {
  int get statusCode;
  Map<String, String> get headers;
  Object? get body;
  String? get contentType;
  DianaResponse change({
    Map<String, Object?>? headers,
    Map<String, Object?>? context,
    Object? body,
  });

  // Instance methods
  DianaResponse copyWith({
    int? statusCode,
    Map<String, String>? headers,
    Object? body,
  });

  DianaResponse withHeader(String name, String value);
  DianaResponse withHeaders(Map<String, String> headers);
  DianaResponse withContentType(String contentType);
  DianaResponse withStatus(int statusCode);

  // Convenience getters
  bool get isSuccess => statusCode >= 200 && statusCode < 300;
  bool get isRedirect => statusCode >= 300 && statusCode < 400;
  bool get isClientError => statusCode >= 400 && statusCode < 500;
  bool get isServerError => statusCode >= 500;
  bool get isError => statusCode >= 400;
}

/// Factory interface for creating HTTP responses
/// Framework adapters must implement this to provide response creation
abstract class DianaResponseFactory {
  DianaResponse create({
    required int statusCode,
    Map<String, String>? headers,
    Object? body,
  });

  DianaResponse ok(
    Object? body, {
    Map<String, String>? headers,
    String? contentType,
  });

  DianaResponse text(
    String body, {
    int statusCode = 200,
    Map<String, String>? headers,
  });

  DianaResponse json(
    Object? body, {
    int statusCode = 200,
    Map<String, String>? headers,
  });

  DianaResponse html(
    String body, {
    int statusCode = 200,
    Map<String, String>? headers,
  });

  DianaResponse redirect(
    String location, {
    int statusCode = 302,
    Map<String, String>? headers,
  });

  DianaResponse noContent({Map<String, String>? headers});

  DianaResponse notFound([String? message]);

  DianaResponse internalServerError([String? message]);

  DianaResponse badRequest([String? message]);

  DianaResponse unauthorized([String? message]);

  DianaResponse forbidden([String? message]);

  DianaResponse sse(
    Stream<String> stream, {
    int statusCode = 200,
    Map<String, String>? headers,
  });
}

typedef DianaHandler = Future<DianaResponse> Function(DianaRequest request);
typedef DianaMiddleware = DianaHandler Function(DianaHandler next);

/// Configuration for static file serving
class StaticFileServerConfig {
  final String localPath;
  final String? defaultDocument;
  final bool listDirectories;
  final bool followLinks;
  final Map<String, String> headers;

  const StaticFileServerConfig({
    required this.localPath,
    this.defaultDocument,
    this.listDirectories = false,
    this.followLinks = true,
    this.headers = const {},
  });
}

/// Factory interface for creating static file server handlers
/// Framework adapters must implement this to provide static file serving
abstract class DianaStaticFileServerFactory {
  DianaHandler createStaticFileServer(StaticFileServerConfig config);
}

/// Factory interface for creating framework-specific middleware
/// Each HTTP framework should implement this to provide middleware integration
abstract class DianaMiddlewareAdapterFactory {
  /// Creates framework-specific middleware from Diana guard
  dynamic createGuardMiddleware(AbstractGuard guard);

  /// Creates framework-specific middleware from Diana middleware
  dynamic createMiddleware(AbstractMiddleware middleware);

  /// Creates framework-specific middleware from Diana interceptor
  dynamic createInterceptorMiddleware(AbstractInterceptor interceptor);
}
