class InternalServerErrorException implements Exception {
  final String message;
  final int statusCode = 500;

  InternalServerErrorException(this.message);

  @override
  String toString() => 'InternalServerErrorException: $message';
}
