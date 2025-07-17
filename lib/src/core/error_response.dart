import 'dart:io';

import 'package:diana/src/core/base/abstract_error_handler.dart';
import 'package:diana/src/core/base/base.dart';
import 'package:diana/src/core/content_type_registry.dart';
import 'package:diana/src/core/exceptions/exceptions.dart';
import 'package:diana/src/core/response_factory_registry.dart';
import 'package:diana/src/http/interfaces.dart';

class ErrorResponse {
  /// Creates a framework-agnostic error middleware
  static DianaMiddleware dianaErrorResponse(
    String outputContentType, [
    DianaHttpErrorBuilder? errorBuilder,
  ]) {
    return (DianaHandler innerHandler) {
      return (DianaRequest request) async {
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
          return ResponseFactoryRegistry.factory.create(
            statusCode: 500,
            body: {
              'error': true,
              'message': httpException.message,
              'statusCode': 500,
              'timestamp': DateTime.now().toIso8601String(),
            }.toString(),
            headers: _getHeaders(request),
          );
        } catch (error, stackTrace) {
          // Log the error or handle it as needed
          print('Error occurred: $error: $stackTrace');
          return ResponseFactoryRegistry.factory.create(
            statusCode: 500,
            body: {
              'error': true,
              'message': 'Internal Server Error',
              'statusCode': 500,
              'timestamp': DateTime.now().toIso8601String(),
              'details': error.toString(),
            }.toString(),
            headers: _getHeaders(request),
          );
        }
      };
    };
  }

  static Map<String, String> _getHeaders(DianaRequest request) {
    return {
      'X-Request-ID': request.context['request_id']?.toString() ?? '',
      'error': 'true',
    };
  }

  static DianaResponse _handleDianaHttpException(
    DianaHttpException exception,
    DianaRequest request,
    String outputContentType,
    dynamic Function(DianaHttpException)? errorBuilder,
  ) {
    final acceptType = request.header('accept') ?? outputContentType;
    final contentTypeHandler = ContentTypeRegistry.getContentTypeHandler(
      acceptType,
    );
    if (acceptType.contains('text/plain') ||
        contentTypeHandler == null ||
        contentTypeHandler is! Serializable) {
      return ResponseFactoryRegistry.factory.create(
        statusCode: exception.statusCode,
        body: _createResponseBody(exception, true),
        headers: _getHeaders(request),
      );
    }

    final responseBody = errorBuilder != null
        ? errorBuilder(exception)
        : _createResponseBody(exception, false);
    return ResponseFactoryRegistry.factory.create(
      statusCode: exception.statusCode,
      body: (contentTypeHandler as Serializable).serialize(responseBody),
      headers: {'Content-Type': acceptType, ..._getHeaders(request)},
    );
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

  /// Creates a framework-agnostic custom error middleware
  static DianaMiddleware customErrorResponse(
    AbstractErrorHandler errorHandler,
  ) {
    return (DianaHandler innerHandler) {
      return (DianaRequest request) async {
        try {
          return await innerHandler(request);
        } catch (error, stackTrace) {
          return await errorHandler.handle(error, stackTrace, request);
        }
      };
    };
  }
}
