import 'diana_http_exception.dart';

class MethodNotAllowedException extends DianaHttpException {
  MethodNotAllowedException(super.message, {super.data, super.uri})
    : super(statusCode: 405, errorCode: 'METHOD_NOT_ALLOWED');

  @override
  String toString() => 'MethodNotAllowedException: ${super.toString()}';
}
