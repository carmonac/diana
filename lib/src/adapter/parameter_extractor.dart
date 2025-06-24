import '../core/exceptions/exceptions.dart';
import 'package:shelf/shelf.dart';
import 'body_parser.dart';
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
        return params?[param.name];
      case ParameterType.query:
        if (param.name == null) {
          return request.url.queryParameters;
        }
        return request.url.queryParameters[param.name];
      case ParameterType.queryList:
        if (param.name == null) {
          return request.url.queryParametersAll;
        }
        return request.url.queryParametersAll[param.name] ?? [];
      case ParameterType.header:
        if (param.name == null) {
          return request.headers;
        }
        return request.headers[param.name];
      case ParameterType.body:
        return await BodyParser.parseBodyParameter(request, param);
      case ParameterType.cookie:
        if (param.name == null) {
          return request.context['shelf.cookies'] as Map<String, String>?;
        }
        final cookies =
            request.context['shelf.cookies'] as Map<String, String>?;
        return cookies?[param.name];
      case ParameterType.formData:
        final formData =
            request.context['shelf.formData'] as Map<String, String>?;
        return formData?[param.name];
      case ParameterType.file:
        final files = request.context['shelf.files'] as Map<String, dynamic>?;
        if (param.name == null) {
          return files;
        }
        return files?[param.name];
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
}
