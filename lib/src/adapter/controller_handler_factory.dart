import 'package:shelf/shelf.dart';
import '../core/handler_composer.dart';
import 'parameter_extractor.dart';
import 'response_processor.dart';
import '../core/action_invoker.dart';

class ControllerHandlerFactory {
  static Handler createOptimizedHandler<T extends Function>(
    T action,
    List<dynamic> params, {
    required String outputContentType, // Default output content type
  }) {
    return (Request request) async {
      final acceptType = request.headers['accept'] ?? outputContentType;

      final parameterObjects = params.whereType<Parameter>().toList();
      dynamic responseFromController;
      switch (parameterObjects.length) {
        case 0:
          responseFromController = await _createTypedHandler0(
            () async => await action(),
          );
        case 1:
          responseFromController = await _createTypedHandler1(
            request,
            (arg1) => action(arg1),
            parameterObjects[0],
          );
        case 2:
          responseFromController = await _createTypedHandler2(
            request,
            (arg1, arg2) => action(arg1, arg2),
            parameterObjects[0],
            parameterObjects[1],
          );
        default:
          responseFromController = await _createHandler(
            request,
            action,
            params,
          );
      }

      return (ResponseProcessor.processResponse(
        responseFromController,
        acceptType,
      )).shelfResponse;
    };
  }

  static Future<dynamic> _createHandler<T extends Function>(
    Request request,
    T action,
    List<dynamic> params,
  ) async {
    final extractedArgs = await ParameterExtractor.extractParametersAsync(
      request,
      params,
    );

    return await ActionInvoker.invoke(action, extractedArgs);
  }

  static Future<R> _createTypedHandler0<R>(Future<R> Function() action) async {
    return await action();
  }

  static Future<R> _createTypedHandler1<R, T1>(
    Request request,
    Future<R> Function(T1) action,
    Parameter param1,
  ) async {
    final arg1 = await ParameterExtractor.extractSingleParameterAsync<T1>(
      request,
      param1,
    );
    return await action(arg1);
  }

  static Future<R> _createTypedHandler2<R, T1, T2>(
    Request request,
    Future<R> Function(T1, T2) action,
    Parameter param1,
    Parameter param2,
  ) async {
    final arg1 = await ParameterExtractor.extractSingleParameterAsync<T1>(
      request,
      param1,
    );
    final arg2 = await ParameterExtractor.extractSingleParameterAsync<T2>(
      request,
      param2,
    );
    return await action(arg1, arg2);
  }
}
