import 'diana_http_exception.dart';

class BadGatewayException extends DianaHttpException {
  BadGatewayException(super.message, {super.data, super.uri})
    : super(statusCode: 502, errorCode: 'BAD_GATEWAY');

  @override
  String toString() => 'BadGatewayException: ${super.toString()}';
}
