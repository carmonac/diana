import 'diana_http_exception.dart';

class NotAcceptableException extends DianaHttpException {
  NotAcceptableException(super.message, {super.data, super.uri})
    : super(statusCode: 406, errorCode: 'NOT_ACCEPTABLE');

  @override
  String toString() => 'NotAcceptableException: ${super.toString()}';
}
