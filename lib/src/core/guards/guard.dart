import '../http/request.dart';
import '../http/response.dart';

/// Result of a guard check
class GuardResult {
  final bool canActivate;
  final DianaResponse? response;
  final Map<String, Object?>? contextData;

  const GuardResult._({
    required this.canActivate,
    this.response,
    this.contextData,
  });

  /// Creates a result that allows the request to continue
  factory GuardResult.allow({Map<String, Object?>? contextData}) {
    return GuardResult._(canActivate: true, contextData: contextData);
  }

  /// Creates a result that blocks the request with a custom response
  factory GuardResult.deny(DianaResponse response) {
    return GuardResult._(canActivate: false, response: response);
  }

  /// Creates a result that blocks the request with an unauthorized response
  factory GuardResult.unauthorized([String? message]) {
    return GuardResult._(
      canActivate: false,
      response: DianaResponse(401, body: message ?? 'Unauthorized'),
    );
  }

  /// Creates a result that blocks the request with a forbidden response
  factory GuardResult.forbidden([String? message]) {
    return GuardResult._(
      canActivate: false,
      response: DianaResponse(403, body: message ?? 'Forbidden'),
    );
  }
}

/// Abstract base class for creating custom guards in Diana framework
abstract class DianaGuard {
  /// Optional configuration data passed from the @Guard annotation
  Map<String, dynamic>? config;

  /// Check if the request can activate/continue
  ///
  /// [request] - The incoming HTTP request
  /// [config] - Optional configuration data from the @Guard annotation
  ///
  /// Returns a [GuardResult] indicating whether the request should continue
  /// and optionally providing additional context data or a custom response
  Future<GuardResult> canActivate(
    DianaRequest request, [
    Map<String, dynamic>? config,
  ]);

  /// Set configuration for this guard instance
  void setConfig(Map<String, dynamic>? config) {
    this.config = config;
  }
}

/// Composite guard that runs multiple guards in sequence
class CompositeGuard extends DianaGuard {
  final List<DianaGuard> _guards;

  CompositeGuard(this._guards);

  @override
  Future<GuardResult> canActivate(
    DianaRequest request, [
    Map<String, dynamic>? config,
  ]) async {
    var currentRequest = request;
    final allContextData = <String, Object?>{};

    for (final guard in _guards) {
      final result = await guard.canActivate(currentRequest, config);

      if (!result.canActivate) {
        return result;
      }

      // Merge context data from successful guards
      if (result.contextData != null) {
        allContextData.addAll(result.contextData!);
        currentRequest = currentRequest.copyWith(context: allContextData);
      }
    }

    return GuardResult.allow(contextData: allContextData);
  }
}
