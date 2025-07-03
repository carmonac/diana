import 'diana_http_exception.dart';

class TooManyRequestsException extends DianaHttpException {
  TooManyRequestsException(super.message, {super.data, super.uri})
    : super(statusCode: 429, errorCode: 'TOO_MANY_REQUESTS');

  @override
  String toString() => 'TooManyRequestsException: ${super.toString()}';
}
