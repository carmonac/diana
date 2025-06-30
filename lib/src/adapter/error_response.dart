import 'dart:io';

import 'package:shelf/shelf.dart';
import '../core/base/base.dart';
import '../core/content_type_registry.dart';
import '../core/exceptions/exceptions.dart';
import 'response.dart';

class ErrorResponse {
  static Middleware dianaErrorResponse(
    String outputContentType, [
    DianaHttpErrorBuilder? errorBuilder,
  ]) {
    return (Handler innerHandler) {
      return (Request request) async {
        try {
          return await innerHandler(request);
        } on DianaHttpException catch (dianaHttpException) {
          return _handleDianaHttpException(
            dianaHttpException,
            request,
            outputContentType,
            errorBuilder,
          );
        } on HttpException catch (httpException) {
          return DianaResponse.text(
            {
              'error': true,
              'message': httpException.message,
              'statusCode': 500,
              'timestamp': DateTime.now().toIso8601String(),
            }.toString(),
            statusCode: 500,
            headers: _getHeaders(request),
          ).shelfResponse;
        } catch (error, stackTrace) {
          // Log the error or handle it as needed
          print('Error occurred: $error: $stackTrace');
          return DianaResponse.text(
            {
              'error': true,
              'message': 'Internal Server Error',
              'statusCode': 500,
              'timestamp': DateTime.now().toIso8601String(),
              'details': error.toString(),
            }.toString(),
            statusCode: 500,
            headers: _getHeaders(request),
          ).shelfResponse;
        }
      };
    };
  }

  static Map<String, String> _getHeaders(Request request) {
    return {
      'X-Request-ID': request.context['request_id']?.toString() ?? '',
      'error': 'true',
    };
  }

  static Response _handleDianaHttpException(
    DianaHttpException exception,
    Request request,
    String outputContentType,
    dynamic Function(DianaHttpException)? errorBuilder,
  ) {
    final acceptType = request.headers['accept'] ?? outputContentType;
    final contentTypeHandler = ContentTypeRegistry.getContentTypeHandler(
      acceptType,
    );
    if (acceptType.contains('text/plain') ||
        contentTypeHandler == null ||
        contentTypeHandler is! Serializable) {
      return DianaResponse.text(
        _createResponseBody(exception, true),
        statusCode: exception.statusCode,
        headers: _getHeaders(request),
      ).shelfResponse;
    }

    final responseBody = errorBuilder != null
        ? errorBuilder(exception)
        : _createResponseBody(exception, false);
    return DianaResponse(
      exception.statusCode,
      body: (contentTypeHandler as Serializable).serialize(responseBody),
      headers: {'Content-Type': acceptType, ..._getHeaders(request)},
    ).shelfResponse;
  }

  static dynamic _createResponseBody(
    DianaHttpException exception,
    bool plainText,
  ) {
    final baseResponse = <String, dynamic>{
      'error': true,
      'message': exception.message,
      'statusCode': exception.statusCode,
      'errorCode': exception.errorCode,
      'timestamp': DateTime.now().toIso8601String(),
    };

    if (exception.data != null) {
      baseResponse['data'] = exception.data!;
    }

    if (plainText) {
      final buffer = StringBuffer();
      buffer.writeln('Error: ${exception.message}');
      buffer.writeln('Status Code: ${exception.statusCode}');
      buffer.writeln('Error Code: ${exception.errorCode}');
      buffer.writeln('Timestamp: ${baseResponse['timestamp']}');

      if (exception.data != null) {
        buffer.writeln('Additional Data: ${exception.data}');
      }

      return buffer.toString();
    }

    return baseResponse;
  }
}
