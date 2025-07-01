import 'package:get_it/get_it.dart';

typedef FactoryFunc<T> = T Function();

/// A service locator for managing dependency injection.
/// It is a wrapper around `get_it`.
class ServiceLocator {
  static final GetIt _getIt = GetIt.instance;

  /// Registers a singleton service.
  /// Only one instance of the service will be created.
  static void registerSingleton<T extends Object>(T instance) {
    _getIt.registerSingleton<T>(instance);
  }

  /// Registers a lazy singleton service.
  /// The instance will be created only when it is first requested.
  /// This is useful for handling circular dependencies.
  static void registerLazySingleton<T extends Object>(FactoryFunc<T> factory) {
    _getIt.registerLazySingleton<T>(factory);
  }

  /// Registers a transient service.
  /// A new instance of the service will be created each time it is requested.
  static void registerTransient<T extends Object>(FactoryFunc<T> factory) {
    _getIt.registerFactory<T>(factory);
  }

  /// Registers a scoped service.
  /// A new instance of the service will be created for each scope.
  static void registerScoped<T extends Object>(FactoryFunc<T> factory) {
    _getIt.registerFactory<T>(factory);
  }

  /// Retrieves a service from the service locator.
  static T get<T extends Object>() {
    return _getIt.get<T>();
  }

  /// Pushes a new scope.
  static void pushScope(String scopeId) {
    _getIt.pushNewScope(scopeName: scopeId);
  }

  /// Pops a scope.
  static Future<void> popScope() async {
    await _getIt.popScope();
  }
}
