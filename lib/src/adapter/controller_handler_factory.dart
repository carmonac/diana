import 'package:shelf/shelf.dart';
import '../core/handler_composer.dart';
import 'parameter_extractor.dart';
import 'response_processor.dart';
import '../core/action_invoker.dart';

class ControllerHandlerFactory {
  static Handler createHandler<T extends Function>(
    T action,
    List<dynamic> params,
  ) {
    return (Request request) async {
      final extractedArgs = await ParameterExtractor.extractParametersAsync(
        request,
        params,
      );

      final responseFromController = await ActionInvoker.invoke(
        action,
        extractedArgs,
      );

      return (ResponseProcessor.processResponse(
        responseFromController,
      )).shelfResponse;
    };
  }

  static Handler createOptimizedHandler<T extends Function>(
    T action,
    List<dynamic> params,
  ) {
    final parameterObjects = params.whereType<Parameter>().toList();

    switch (parameterObjects.length) {
      case 0:
        return _createTypedHandler0(() => action());
      case 1:
        return _createTypedHandler1(
          (arg1) => action(arg1),
          parameterObjects[0],
        );
      case 2:
        return _createTypedHandler2(
          (arg1, arg2) => action(arg1, arg2),
          parameterObjects[0],
          parameterObjects[1],
        );
      default:
        return createHandler(action, params);
    }
  }

  static Handler _createTypedHandler0<R>(R Function() action) {
    return (Request request) async {
      final result = action();
      return (ResponseProcessor.processResponse(result)).shelfResponse;
    };
  }

  static Handler _createTypedHandler1<R, T1>(
    R Function(T1) action,
    Parameter param1,
  ) {
    return (Request request) async {
      final arg1 = await ParameterExtractor.extractSingleParameterAsync<T1>(
        request,
        param1,
      );
      final result = action(arg1);
      return (ResponseProcessor.processResponse(result)).shelfResponse;
    };
  }

  static Handler _createTypedHandler2<R, T1, T2>(
    R Function(T1, T2) action,
    Parameter param1,
    Parameter param2,
  ) {
    return (Request request) async {
      final arg1 = await ParameterExtractor.extractSingleParameterAsync<T1>(
        request,
        param1,
      );
      final arg2 = await ParameterExtractor.extractSingleParameterAsync<T2>(
        request,
        param2,
      );
      final result = action(arg1, arg2);
      return (ResponseProcessor.processResponse(result)).shelfResponse;
    };
  }
}
