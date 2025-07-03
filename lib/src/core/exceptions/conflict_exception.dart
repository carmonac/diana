import 'diana_http_exception.dart';

class ConflictException extends DianaHttpException {
  ConflictException(super.message, {super.data, super.uri})
    : super(statusCode: 409, errorCode: 'CONFLICT');

  @override
  String toString() => 'ConflictException: ${super.toString()}';
}
