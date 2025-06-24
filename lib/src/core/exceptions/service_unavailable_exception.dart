import 'diana_http_exception.dart';

class ServiceUnavailableException extends DianaHttpException {
  ServiceUnavailableException(super.message, {super.data, super.uri})
    : super(statusCode: 503, errorCode: 'SERVICE_UNAVAILABLE');

  @override
  String toString() => 'ServiceUnavailableException: ${super.toString()}';
}
