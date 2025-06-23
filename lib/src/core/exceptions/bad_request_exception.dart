class BadRequestException implements Exception {
  final String message;
  final int statusCode = 400;

  BadRequestException(this.message);

  @override
  String toString() => 'BadRequestException: $message';
}
