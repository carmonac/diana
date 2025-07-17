import 'dart:io' as io;

import 'package:diana/src/core/base/base.dart';
import 'package:diana/src/core/exceptions/exceptions.dart';
import 'package:diana/src/core/handler_composer.dart';
import 'package:diana/src/core/parameter_type.dart';
import 'package:diana/src/core/type_converter.dart';
import 'package:diana/src/http/interfaces.dart';

import 'body_parser.dart';
import 'file_parser.dart';
import 'secure_cookie_handler.dart';
import 'secure_session_handler.dart';

class ParameterExtractor {
  static Future<List<dynamic>> extractParametersAsync(
    DianaRequest request,
    List<dynamic> params,
  ) async {
    final extractedArgs = <dynamic>[];

    for (final param in params) {
      if (param is Parameter) {
        final value = await _extractParameterValue(request, param);
        extractedArgs.add(value);
      } else {
        extractedArgs.add(param);
      }
    }

    return extractedArgs;
  }

  static Future<T> extractSingleParameterAsync<T>(
    DianaRequest request,
    Parameter param,
  ) async {
    final value = await _extractParameterValue(request, param);

    if (value != null && param.type != ParameterType.body) {
      return TypeConverter.convertToType<T>(value);
    }

    return value as T;
  }

  static Future<dynamic> _extractParameterValue(
    DianaRequest request,
    Parameter param,
  ) async {
    switch (param.type) {
      case ParameterType.path:
        if (param.name == null) {
          return request.context['shelf_router/params'] as Map<String, String>?;
        }
        final params =
            request.context['shelf_router/params'] as Map<String, String>?;
        return _processValue(params?[param.name], param);
      case ParameterType.query:
        if (param.name == null) {
          return _processValue(request.queryParametersAll, param);
        }
        return _processValue(request.queryParameters[param.name], param);

      case ParameterType.header:
        if (param.name == null) {
          return _processValue(request.headers, param);
        }
        return _processValue(request.headers[param.name], param);

      case ParameterType.body:
        Object obj = await BodyParser.parseBodyParameter(request, param);
        return _processValue(obj, param);
      case ParameterType.cookie:
        return request.getContext('cookie_handler') as SecureCookieHandler;
      case ParameterType.file:
        return await FileParser.parseFileParameter(request, param);
      case ParameterType.session:
        return SecureSessionHandler.getSession(request);
      case ParameterType.request:
        return request;
      case ParameterType.ip:
        return (request.connectionInfo() as io.HttpConnectionInfo)
            .remoteAddress
            .address;
      case ParameterType.host:
        return request.host;
      default:
        return null;
    }
  }

  static dynamic _processValue(dynamic value, Parameter param) {
    if (value == null) {
      return null;
    }
    _executeValidators(param.validators, value);
    return _executeTransformers(param.transformers, value);
  }

  static void _executeValidators(
    List<AbstractValidator>? validators,
    dynamic value,
  ) async {
    if (validators == null || validators.isEmpty) {
      return;
    }
    for (final validator in validators) {
      final (isValid, errorMessage) = await validator.isValid(value);
      if (!isValid) {
        throw BadRequestException(errorMessage);
      }
    }
  }

  static Object _executeTransformers(
    List<AbstractTransformer>? transformers,
    Object value,
  ) {
    if (transformers == null || transformers.isEmpty) {
      return value;
    }
    for (final transformer in transformers) {
      value = transformer.transform(value);
    }
    return value;
  }
}
