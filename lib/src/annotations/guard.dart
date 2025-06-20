/// Annotation to apply guards to controllers or individual route methods
class Guard {
  /// The guard class type to apply
  final Type guardType;

  /// Optional configuration data for the guard
  final Map<String, dynamic>? config;

  const Guard(this.guardType, [this.config]);
}

/// Annotation to apply multiple guards to controllers or individual route methods
class GuardsAnnotation {
  /// List of guard configurations
  final List<GuardConfig> guards;

  const GuardsAnnotation(this.guards);
}

/// Configuration for a single guard
class GuardConfig {
  /// The guard class type to apply
  final Type guardType;

  /// Optional configuration data for the guard
  final Map<String, dynamic>? config;

  const GuardConfig(this.guardType, [this.config]);
}
