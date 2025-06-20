import 'http_status.dart';

abstract class HttpException implements Exception {
  final int statusCode;
  final String message;
  final Map<String, dynamic>? extras;

  HttpException(this.statusCode, this.message, [this.extras]);

  Map<String, dynamic> toJson() => {
    'error': message,
    'status': statusCode,
    if (extras != null) ...extras!,
  };
}

class BadRequest extends HttpException {
  BadRequest(String message, [Map<String, dynamic>? extras])
    : super(HttpStatus.badRequest.value, message, extras);
}

class Unauthorized extends HttpException {
  Unauthorized([String message = 'Unauthorized', Map<String, dynamic>? extras])
    : super(HttpStatus.unauthorized.value, message, extras);
}

class NotFound extends HttpException {
  NotFound([String message = 'Not Found', Map<String, dynamic>? extras])
    : super(HttpStatus.notFound.value, message, extras);
}

class InternalServerError extends HttpException {
  InternalServerError([
    String message = 'Internal Server Error',
    Map<String, dynamic>? extras,
  ]) : super(HttpStatus.internalServerError.value, message, extras);
}

class ServiceUnavailable extends HttpException {
  ServiceUnavailable([
    String message = 'Service Unavailable',
    Map<String, dynamic>? extras,
  ]) : super(HttpStatus.serviceUnavailable.value, message, extras);
}

class Conflict extends HttpException {
  Conflict([String message = 'Conflict', Map<String, dynamic>? extras])
    : super(HttpStatus.conflict.value, message, extras);
}

class Forbidden extends HttpException {
  Forbidden([String message = 'Forbidden', Map<String, dynamic>? extras])
    : super(HttpStatus.forbidden.value, message, extras);
}

class MethodNotAllowed extends HttpException {
  MethodNotAllowed([
    String message = 'Method Not Allowed',
    Map<String, dynamic>? extras,
  ]) : super(HttpStatus.methodNotAllowed.value, message, extras);
}

class NotAcceptable extends HttpException {
  NotAcceptable([
    String message = 'Not Acceptable',
    Map<String, dynamic>? extras,
  ]) : super(HttpStatus.notAcceptable.value, message, extras);
}

class RequestTimeout extends HttpException {
  RequestTimeout([
    String message = 'Request Timeout',
    Map<String, dynamic>? extras,
  ]) : super(HttpStatus.requestTimeout.value, message, extras);
}

class PayloadTooLarge extends HttpException {
  PayloadTooLarge([
    String message = 'Payload Too Large',
    Map<String, dynamic>? extras,
  ]) : super(HttpStatus.payloadTooLarge.value, message, extras);
}

class PreconditionFailed extends HttpException {
  PreconditionFailed([
    String message = 'Precondition Failed',
    Map<String, dynamic>? extras,
  ]) : super(HttpStatus.preconditionFailed.value, message, extras);
}

class UnsupportedMediaType extends HttpException {
  UnsupportedMediaType([
    String message = 'Unsupported Media Type',
    Map<String, dynamic>? extras,
  ]) : super(HttpStatus.unsupportedMediaType.value, message, extras);
}

class TooManyRequests extends HttpException {
  TooManyRequests([
    String message = 'Too Many Requests',
    Map<String, dynamic>? extras,
  ]) : super(HttpStatus.tooManyRequests.value, message, extras);
}

class NotImplemented extends HttpException {
  NotImplemented([
    String message = 'Not Implemented',
    Map<String, dynamic>? extras,
  ]) : super(HttpStatus.notImplemented.value, message, extras);
}

class BadGateway extends HttpException {
  BadGateway([String message = 'Bad Gateway', Map<String, dynamic>? extras])
    : super(HttpStatus.badGateway.value, message, extras);
}

class GatewayTimeout extends HttpException {
  GatewayTimeout([
    String message = 'Gateway Timeout',
    Map<String, dynamic>? extras,
  ]) : super(HttpStatus.gatewayTimeout.value, message, extras);
}

class HttpExceptionHandler {
  static void handle(HttpException exception) {
    print('HTTP Exception: ${exception.statusCode} - ${exception.message}');
    if (exception.extras != null) {
      print('Extras: ${exception.extras}');
    }
  }
}
