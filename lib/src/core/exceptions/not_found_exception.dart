class NotFoundException implements Exception {
  final String message;
  final int statusCode = 404;

  NotFoundException(this.message);

  @override
  String toString() => 'NotFoundException: $message';
}
