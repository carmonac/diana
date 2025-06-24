import 'diana_http_exception.dart';

class InternalServerErrorException extends DianaHttpException {
  InternalServerErrorException(super.message, {super.data, super.uri})
    : super(statusCode: 500, errorCode: 'INTERNAL_SERVER_ERROR');
  @override
  String toString() => 'InternalServerErrorException: $message';
}
