import 'diana_http_exception.dart';

class GatewayTimeoutException extends DianaHttpException {
  GatewayTimeoutException(super.message, {super.data, super.uri})
    : super(statusCode: 504, errorCode: 'GATEWAY_TIMEOUT');

  @override
  String toString() => 'GatewayTimeoutException: ${super.toString()}';
}
