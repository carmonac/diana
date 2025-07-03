import 'diana_http_exception.dart';

class UnprocessableEntityException extends DianaHttpException {
  UnprocessableEntityException(super.message, {super.data, super.uri})
    : super(statusCode: 422, errorCode: 'UNPROCESSABLE_ENTITY');

  @override
  String toString() => 'UnprocessableEntityException: ${super.toString()}';
}
