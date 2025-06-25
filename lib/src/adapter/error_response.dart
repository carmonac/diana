import 'dart:io';

import 'package:shelf/shelf.dart';
import '../core/exceptions/exceptions.dart';
import 'response.dart';

class ErrorResponse {
  static Middleware dianaErrorResponse() {
    return (Handler innerHandler) {
      return (Request request) async {
        try {
          return await innerHandler(request);
        } on DianaHttpException catch (dianaHttpException) {
          return _handleDianaHttpException(dianaHttpException, request);
        } on HttpException catch (httpException) {
          return DianaResponse.json(
            {
              'error': true,
              'message': httpException.message,
              'statusCode': 500,
              'timestamp': DateTime.now().toIso8601String(),
            },
            statusCode: 500,
            headers: _getHeaders(request),
          ).shelfResponse;
        } catch (error, stackTrace) {
          // Log the error or handle it as needed
          print('Error occurred: $error: $stackTrace');
          return DianaResponse.json(
            {
              'error': true,
              'message': 'Internal Server Error',
              'statusCode': 500,
              'timestamp': DateTime.now().toIso8601String(),
              'details': error.toString(),
            },
            statusCode: 500,
            headers: _getHeaders(request),
          ).shelfResponse;
        }
      };
    };
  }

  static Map<String, String> _getHeaders(Request request) {
    return {
      'Content-Type': 'application/json',
      'X-Request-ID': request.context['request_id']?.toString() ?? '',
    };
  }

  static Response _handleDianaHttpException(
    DianaHttpException exception,
    Request request,
  ) {
    final acceptHeader = request.headers['accept'] ?? 'application/json';
    final contentType = _determineContentType(acceptHeader);

    // Crear el cuerpo de la respuesta
    final responseBody = _createResponseBody(exception, contentType);

    // Usar DianaResponse según el tipo de contenido
    switch (contentType) {
      case 'application/xml':
        return DianaResponse.xml(
          responseBody,
          statusCode: exception.statusCode,
          headers: _getHeaders(request),
        ).shelfResponse;
      case 'text/plain':
        return DianaResponse.text(
          responseBody.toString(),
          statusCode: exception.statusCode,
          headers: _getHeaders(request),
        ).shelfResponse;
      default: // application/json
        return DianaResponse.json(
          responseBody,
          statusCode: exception.statusCode,
          headers: _getHeaders(request),
        ).shelfResponse;
    }
  }

  static String _determineContentType(String acceptHeader) {
    // Normalizar el header accept
    final accept = acceptHeader.toLowerCase();

    if (accept.contains('application/xml') || accept.contains('text/xml')) {
      return 'application/xml';
    } else if (accept.contains('text/plain')) {
      return 'text/plain';
    } else {
      // Por defecto JSON
      return 'application/json';
    }
  }

  static dynamic _createResponseBody(
    DianaHttpException exception,
    String contentType,
  ) {
    final baseResponse = <String, dynamic>{
      'error': true,
      'message': exception.message,
      'statusCode': exception.statusCode,
      'errorCode': exception.errorCode,
      'timestamp': DateTime.now().toIso8601String(),
    };

    // Si la excepción tiene data, la incluimos
    if (exception.data != null) {
      baseResponse['data'] = exception.data!;
    }

    // Para texto plano, convertir a string simple
    if (contentType == 'text/plain') {
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
