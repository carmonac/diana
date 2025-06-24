import 'diana_http_exception.dart';

class PayloadTooLargeException extends DianaHttpException {
  PayloadTooLargeException(super.message, {super.data, super.uri})
    : super(statusCode: 413, errorCode: 'PAYLOAD_TOO_LARGE');

  @override
  String toString() => 'PayloadTooLargeException: ${super.toString()}';
}
