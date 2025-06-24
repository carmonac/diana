import 'diana_http_exception.dart';

class RequestTimeoutException extends DianaHttpException {
  RequestTimeoutException(super.message, {super.data, super.uri})
    : super(statusCode: 408, errorCode: 'REQUEST_TIMEOUT');

  @override
  String toString() => 'RequestTimeoutException: ${super.toString()}';
}
