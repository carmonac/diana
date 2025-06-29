import '../core/exceptions/exceptions.dart';
import 'package:shelf/shelf.dart';
import 'body_parser.dart';
import 'file_parser.dart';
import '../core/base/base.dart';
import '../core/handler_composer.dart';
import '../core/type_converter.dart';
import '../core/parameter_type.dart';
import 'request.dart';

class ParameterExtractor {
  static Future<List<dynamic>> extractParametersAsync(
    Request request,
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
    Request request,
    Parameter param,
  ) async {
    final value = await _extractParameterValue(request, param);

    if (value != null && param.type != ParameterType.body) {
      return TypeConverter.convertToType<T>(value);
    }

    return value as T;
  }

  static Future<dynamic> _extractParameterValue(
    Request request,
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
          return _processValue(request.url.queryParameters, param);
        }
        return _processValue(request.url.queryParameters[param.name], param);

      case ParameterType.queryList:
        if (param.name == null) {
          return _processValue(request.url.queryParametersAll, param);
        }
        return _processValue(
          request.url.queryParametersAll[param.name] ?? [],
          param,
        );

      case ParameterType.header:
        if (param.name == null) {
          return _processValue(request.headers, param);
        }
        return _processValue(request.headers[param.name], param);

      case ParameterType.body:
        Object obj = await BodyParser.parseBodyParameter(request, param);
        return _processValue(obj, param);
      case ParameterType.cookie:
        if (param.name == null) {
          return _processValue(
            request.context['shelf.cookies'] as Map<String, String>?,
            param,
          );
        }
        final cookies =
            request.context['shelf.cookies'] as Map<String, String>?;
        return _processValue(cookies?[param.name], param);
      case ParameterType.file:
        return await FileParser.parseFileParameter(request, param);
      case ParameterType.session:
        final session =
            request.context['shelf.session'] as Map<String, dynamic>?;
        if (param.name == null) {
          return session;
        }
        return session?[param.name];
      case ParameterType.request:
        return DianaRequest.fromShelf(request);
      case ParameterType.ip:
        return request.context['shelf.ip'] ??
            request.headers['x-forwarded-for'];
      case ParameterType.host:
        return request.headers['host'] ?? request.url.host;
      default:
        return null;
    }
  }

  static dynamic _processValue(dynamic value, Parameter param) {
    _executeValidators(param.validators, value);
    return _executeTransformers(param.transformers, value);
  }

  static void _executeValidators(
    List<DianaValidator>? validators,
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
    List<DianaTransformer>? transformers,
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
