import 'dart:io';

class DianaHttpException extends HttpException {
  final int statusCode;
  final String errorCode;
  final Object? data;

  DianaHttpException(
    super.message, {
    this.data,
    required this.statusCode,
    required this.errorCode,
    super.uri,
  });

  @override
  String toString() =>
      'DianaHttpException: $message (Status: $statusCode, Code: $errorCode)';
}

typedef DianaHttpErrorBuilder = dynamic Function(DianaHttpException exception);
