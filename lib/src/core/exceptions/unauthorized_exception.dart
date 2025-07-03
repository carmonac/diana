import 'diana_http_exception.dart';

class UnauthorizedException extends DianaHttpException {
  UnauthorizedException(super.message, {super.data, super.uri})
    : super(statusCode: 401, errorCode: 'UNAUTHORIZED');

  @override
  String toString() => 'UnauthorizedException: ${super.toString()}';
}
