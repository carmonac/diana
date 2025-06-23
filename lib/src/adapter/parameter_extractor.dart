import 'package:shelf/shelf.dart';
import 'body_parser.dart';
import '../core/handler_composer.dart';
import '../core/type_converter.dart';

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

    if (value != null && param.type != parameterType.body) {
      return TypeConverter.convertToType<T>(value);
    }

    return value as T;
  }

  static Future<dynamic> _extractParameterValue(
    Request request,
    Parameter param,
  ) async {
    switch (param.type) {
      case parameterType.path:
        final params =
            request.context['shelf_router/params'] as Map<String, String>?;
        return params?[param.name];
      case parameterType.query:
        return request.url.queryParameters[param.name];
      case parameterType.header:
        return request.headers[param.name];
      case parameterType.body:
        return await BodyParser.parseBodyParameter(request, param);
      default:
        return null;
    }
  }
}
