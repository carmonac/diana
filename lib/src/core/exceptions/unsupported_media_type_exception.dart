import 'diana_http_exception.dart';

class UnsupportedMediaTypeException extends DianaHttpException {
  UnsupportedMediaTypeException(super.message, {super.data, super.uri})
    : super(statusCode: 415, errorCode: 'UNSUPPORTED_MEDIA_TYPE');

  @override
  String toString() => 'UnsupportedMediaTypeException: ${super.toString()}';
}
