class BadRequestException implements Exception {
  final String message;
  final int statusCode = 400;
  final String errorCode = 'BAD_REQUEST';
  Object? data;

  BadRequestException(this.message, {this.data});

  @override
  String toString() => 'BadRequestException: $message';
}
