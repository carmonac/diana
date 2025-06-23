class InternalServerErrorException implements Exception {
  final String message;
  final int statusCode = 500;
  final String errorCode = 'INTERNAL_SERVER_ERROR';
  Object? data;

  InternalServerErrorException(this.message, {this.data});

  @override
  String toString() => 'InternalServerErrorException: $message';
}
