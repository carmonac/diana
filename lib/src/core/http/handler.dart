import 'request.dart';
import 'response.dart';

/// Diana framework HTTP handler type
typedef DianaHandler = Future<DianaResponse> Function(DianaRequest request);
