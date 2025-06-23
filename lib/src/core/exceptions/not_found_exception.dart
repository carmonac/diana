class NotFoundException implements Exception {
  final String message;
  final int statusCode = 404;
  final String errorCode = 'NOT_FOUND';
  Object? data;

  NotFoundException(this.message, {this.data});

  @override
  String toString() => 'NotFoundException: $message';
}
