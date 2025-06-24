import 'diana_http_exception.dart';

class NotFoundException extends DianaHttpException {
  NotFoundException(super.message, {super.data, super.uri})
    : super(statusCode: 404, errorCode: 'NOT_FOUND');
  @override
  String toString() => 'NotFoundException: $message';
}
