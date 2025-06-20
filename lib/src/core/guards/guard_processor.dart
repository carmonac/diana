import '../http/request.dart';
import 'guard.dart';
import 'common_guards.dart';

/// Guard processor that handles @Guard annotations and creates guard instances
class GuardProcessor {
  /// Registry of guard types to factory functions
  static final Map<Type, DianaGuard Function()> _guardFactories = {};

  /// Register a guard factory function
  static void registerGuardFactory<T extends DianaGuard>(T Function() factory) {
    _guardFactories[T] = factory;
  }

  /// Create a guard instance using registered factories
  static DianaGuard? createGuardInstance(
    Type guardType, [
    Map<String, dynamic>? config,
  ]) {
    final factory = _guardFactories[guardType];
    if (factory == null) {
      print('Warning: No factory registered for guard type $guardType');
      return null;
    }

    final guard = factory();

    // Apply configuration if provided
    if (config != null) {
      guard.setConfig(config);
    }

    return guard;
  }

  /// Execute a list of guards in sequence
  static Future<GuardResult> executeGuards(
    List<DianaGuard> guards,
    DianaRequest request,
  ) async {
    var currentRequest = request;
    final allContextData = <String, Object?>{};

    for (final guard in guards) {
      final result = await guard.canActivate(currentRequest, guard.config);

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

/// Utility for registering common guards
class GuardRegistry {
  static void registerCommonGuards() {
    GuardProcessor.registerGuardFactory<AuthGuard>(() => AuthGuard());
    GuardProcessor.registerGuardFactory<RoleGuard>(
      () => RoleGuard(requiredRoles: []),
    );
    GuardProcessor.registerGuardFactory<RateLimitGuard>(
      () => RateLimitGuard(maxRequests: 100, timeWindow: Duration(hours: 1)),
    );
  }
}
