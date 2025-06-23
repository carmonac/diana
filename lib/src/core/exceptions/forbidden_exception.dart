class ForbiddenException implements Exception {
  final String message;
  final int statusCode = 403;
  final String errorCode = 'FORBIDDEN';
  Object? data;

  ForbiddenException(this.message, {this.data});

  @override
  String toString() => 'ForbiddenException: $message';
}
