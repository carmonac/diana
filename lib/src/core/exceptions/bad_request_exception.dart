import 'diana_http_exception.dart';

class BadRequestException extends DianaHttpException {
  BadRequestException(super.message, {super.data, super.uri})
    : super(statusCode: 400, errorCode: 'BAD_REQUEST');
  @override
  String toString() => 'BadRequestException: $message';
}
