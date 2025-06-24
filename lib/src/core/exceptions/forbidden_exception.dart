import 'diana_http_exception.dart';

class ForbiddenException extends DianaHttpException {
  ForbiddenException(super.message, {super.data, super.uri})
    : super(statusCode: 403, errorCode: 'FORBIDDEN');
  @override
  String toString() => 'ForbiddenException: ${super.toString()}';
}
