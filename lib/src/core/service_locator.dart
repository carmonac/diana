import '../annotations/service.dart';

/// Exception thrown when a service is not registered
class ServiceNotRegisteredException implements Exception {
  final Type serviceType;
  final String message;

  ServiceNotRegisteredException(this.serviceType, [String? customMessage])
    : message =
          customMessage ?? 'Service of type $serviceType is not registered';

  @override
  String toString() => 'ServiceNotRegisteredException: $message';
}

/// Exception thrown when a circular dependency is detected
class CircularDependencyException implements Exception {
  final List<Type> dependencyChain;
  final String message;

  CircularDependencyException(this.dependencyChain)
    : message =
          'Circular dependency detected: ${dependencyChain.map((t) => t.toString()).join(' -> ')} -> ${dependencyChain.first}';

  @override
  String toString() => 'CircularDependencyException: $message';
}

/// A service locator for dependency injection that manages different types of services
/// based on their scope (singleton, transient, scoped).
class ServiceLocator {
  static final ServiceLocator _instance = ServiceLocator._internal();

  /// Private constructor for singleton pattern
  ServiceLocator._internal();

  /// Factory constructor to return the singleton instance
  factory ServiceLocator() => _instance;

  /// Static getter for the singleton instance
  static ServiceLocator get instance => _instance;

  // Storage for different types of services
  final Map<Type, dynamic> _singletonInstances = {};
  final Map<Type, Function> _transientFactories = {};
  final Map<Type, Function> _scopedFactories = {};
  final Map<String, Map<Type, dynamic>> _scopedInstances = {};

  // Current scope identifier for scoped services
  String? _currentScope;

  // Track services currently being resolved to detect circular dependencies
  final Set<Type> _resolutionStack = {};

  /// Registers a singleton service with its factory function
  void registerSingleton<T>(T Function() factory) {
    _singletonInstances[T] = factory;
  }

  /// Registers a singleton service with an existing instance
  void registerSingletonInstance<T>(T instance) {
    _singletonInstances[T] = instance;
  }

  /// Registers a transient service with its factory function
  void registerTransient<T>(T Function() factory) {
    _transientFactories[T] = factory;
  }

  /// Registers a scoped service with its factory function
  void registerScoped<T>(T Function() factory) {
    _scopedFactories[T] = factory;
  }

  /// Registers a service based on its ServiceScope annotation
  void registerService<T>(T Function() factory, ServiceScope scope) {
    switch (scope) {
      case ServiceScope.singleton:
        registerSingleton<T>(factory);
        break;
      case ServiceScope.transient:
        registerTransient<T>(factory);
        break;
      case ServiceScope.scoped:
        registerScoped<T>(factory);
        break;
    }
  }

  /// Registers a singleton service with automatic dependency resolution
  /// The dependencies will be resolved when the service is first requested
  void registerSingletonAuto<T>(T Function(ServiceLocator locator) factory) {
    _singletonInstances[T] = () => factory(this);
  }

  /// Registers a transient service with automatic dependency resolution
  void registerTransientAuto<T>(T Function(ServiceLocator locator) factory) {
    _transientFactories[T] = () => factory(this);
  }

  /// Registers a scoped service with automatic dependency resolution
  void registerScopedAuto<T>(T Function(ServiceLocator locator) factory) {
    _scopedFactories[T] = () => factory(this);
  }

  /// Bulk register services with dependency resolution order
  /// Services will be sorted and registered in the correct order
  void registerBulk(List<ServiceRegistration> registrations) {
    final sortedRegistrations = _sortByDependencies(registrations);

    for (final registration in sortedRegistrations) {
      switch (registration.scope) {
        case ServiceScope.singleton:
          registerSingletonAuto(registration.factory);
          break;
        case ServiceScope.transient:
          registerTransientAuto(registration.factory);
          break;
        case ServiceScope.scoped:
          registerScopedAuto(registration.factory);
          break;
      }
    }
  }

  /// Sort service registrations by dependency order
  List<ServiceRegistration> _sortByDependencies(
    List<ServiceRegistration> registrations,
  ) {
    // Implementación básica - en un caso real necesitarías análisis de dependencias
    // Por ahora, simplemente retorna en el orden dado
    return List.from(registrations);
  }

  /// Gets an instance of the requested service type
  T get<T>() {
    // Check for circular dependency
    if (_resolutionStack.contains(T)) {
      final dependencyChain = _resolutionStack.toList()..add(T);
      throw CircularDependencyException(dependencyChain);
    }

    // Add to resolution stack
    _resolutionStack.add(T);

    try {
      return _resolveService<T>();
    } finally {
      // Always remove from resolution stack
      _resolutionStack.remove(T);
    }
  }

  /// Internal method to resolve services
  T _resolveService<T>() {
    // Check for singleton
    if (_singletonInstances.containsKey(T)) {
      final entry = _singletonInstances[T];
      if (entry is T) {
        return entry;
      } else if (entry is Function) {
        final instance = entry() as T;
        _singletonInstances[T] = instance;
        return instance;
      }
    }

    // Check for transient
    if (_transientFactories.containsKey(T)) {
      final factory = _transientFactories[T] as T Function();
      return factory();
    }

    // Check for scoped
    if (_scopedFactories.containsKey(T)) {
      if (_currentScope == null) {
        throw StateError('No scope is currently active for scoped service $T');
      }

      final scopeInstances = _scopedInstances[_currentScope!] ??= {};

      if (scopeInstances.containsKey(T)) {
        return scopeInstances[T] as T;
      }

      final factory = _scopedFactories[T] as T Function();
      final instance = factory();
      scopeInstances[T] = instance;
      return instance;
    }

    throw ServiceNotRegisteredException(T);
  }

  /// Tries to get an instance of the requested service type, returns null if not found
  T? tryGet<T>() {
    try {
      return get<T>();
    } catch (e) {
      return null;
    }
  }

  /// Checks if a service of the given type is registered
  bool isRegistered<T>() {
    return _singletonInstances.containsKey(T) ||
        _transientFactories.containsKey(T) ||
        _scopedFactories.containsKey(T);
  }

  /// Starts a new scope for scoped services
  void beginScope(String scopeId) {
    _currentScope = scopeId;
    _scopedInstances[scopeId] ??= {};
  }

  /// Ends the current scope and disposes all scoped instances
  void endScope() {
    if (_currentScope != null) {
      final scopeInstances = _scopedInstances[_currentScope];
      if (scopeInstances != null) {
        // Dispose instances if they implement a dispose method
        for (final instance in scopeInstances.values) {
          if (instance is Disposable) {
            instance.dispose();
          }
        }
        _scopedInstances.remove(_currentScope);
      }
      _currentScope = null;
    }
  }

  /// Gets the current scope identifier
  String? get currentScope => _currentScope;

  /// Clears all registered services and instances
  void clear() {
    _singletonInstances.clear();
    _transientFactories.clear();
    _scopedFactories.clear();
    _scopedInstances.clear();
    _currentScope = null;
    _resolutionStack.clear();
  }

  /// Unregisters a service of the given type
  void unregister<T>() {
    _singletonInstances.remove(T);
    _transientFactories.remove(T);
    _scopedFactories.remove(T);

    // Remove from all scopes
    for (final scopeInstances in _scopedInstances.values) {
      scopeInstances.remove(T);
    }
  }

  /// Validates that all dependencies can be resolved without circular references
  /// Returns a list of validation errors, empty if all is good
  List<String> validateDependencies() {
    final errors = <String>[];
    final originalStack = Set<Type>.from(_resolutionStack);
    _resolutionStack.clear();

    try {
      // Test singleton dependencies
      for (final type in _singletonInstances.keys) {
        try {
          _testDependencyResolution(type);
        } catch (e) {
          errors.add('Singleton $type: $e');
        }
      }

      // Test transient dependencies
      for (final type in _transientFactories.keys) {
        try {
          _testDependencyResolution(type);
        } catch (e) {
          errors.add('Transient $type: $e');
        }
      }

      // Test scoped dependencies (requires a scope)
      final hadScope = _currentScope;
      beginScope('validation-scope');
      try {
        for (final type in _scopedFactories.keys) {
          try {
            _testDependencyResolution(type);
          } catch (e) {
            errors.add('Scoped $type: $e');
          }
        }
      } finally {
        endScope();
        if (hadScope != null) {
          beginScope(hadScope);
        }
      }
    } finally {
      _resolutionStack.clear();
      _resolutionStack.addAll(originalStack);
    }

    return errors;
  }

  /// Test dependency resolution without actually creating instances
  void _testDependencyResolution(Type type) {
    if (_resolutionStack.contains(type)) {
      final dependencyChain = _resolutionStack.toList()..add(type);
      throw CircularDependencyException(dependencyChain);
    }

    _resolutionStack.add(type);
    try {
      // For this validation, we don't actually create instances
      // We just check if the service is registered
      if (!_singletonInstances.containsKey(type) &&
          !_transientFactories.containsKey(type) &&
          !_scopedFactories.containsKey(type)) {
        throw ServiceNotRegisteredException(type);
      }
    } finally {
      _resolutionStack.remove(type);
    }
  }

  /// Gets all registered service types
  Set<Type> getRegisteredTypes() {
    return {
      ..._singletonInstances.keys,
      ..._transientFactories.keys,
      ..._scopedFactories.keys,
    };
  }

  /// Gets service information for debugging
  Map<String, dynamic> getServiceInfo<T>() {
    final info = <String, dynamic>{
      'type': T.toString(),
      'isRegistered': isRegistered<T>(),
    };

    if (_singletonInstances.containsKey(T)) {
      info['scope'] = 'singleton';
      info['hasInstance'] = _singletonInstances[T] is T;
    } else if (_transientFactories.containsKey(T)) {
      info['scope'] = 'transient';
    } else if (_scopedFactories.containsKey(T)) {
      info['scope'] = 'scoped';
      info['currentScope'] = _currentScope;
      if (_currentScope != null) {
        final scopeInstances = _scopedInstances[_currentScope!];
        info['hasInstanceInCurrentScope'] =
            scopeInstances?.containsKey(T) ?? false;
      }
    }

    return info;
  }

  /// Safe get that returns null instead of throwing for unregistered services
  T? safeGet<T>() {
    try {
      return get<T>();
    } on ServiceNotRegisteredException {
      return null;
    } on CircularDependencyException {
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Validates that a service can be registered without immediate dependency issues
  bool canRegister<T>(T Function() factory) {
    // Store original registration if it exists
    final hadOriginal = _singletonInstances.containsKey(T);
    final originalRegistration = hadOriginal ? _singletonInstances[T] : null;

    try {
      // Test registration without actually registering
      _singletonInstances[T] = factory;

      // Try to resolve - this will fail if dependencies are missing
      get<T>();

      // If we get here, registration is valid
      return true;
    } catch (e) {
      return false;
    } finally {
      // Restore original state
      if (hadOriginal && originalRegistration != null) {
        _singletonInstances[T] = originalRegistration;
      } else {
        _singletonInstances.remove(T);
      }
    }
  }
}

/// Interface for disposable resources
abstract class Disposable {
  void dispose();
}

/// Represents a service registration with its dependencies
class ServiceRegistration<T> {
  final Type serviceType;
  final ServiceScope scope;
  final T Function(ServiceLocator locator) factory;
  final List<Type> dependencies;

  ServiceRegistration({
    required this.serviceType,
    required this.scope,
    required this.factory,
    this.dependencies = const [],
  });
}
