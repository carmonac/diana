import 'package:diana/diana.dart';

@Service(ServiceScope.singleton)
class ApplicationConfig {
  /// The Diana configuration for the application.
  DianaConfig dianaConfig = DianaConfig();

  /// Creates a new instance of [ApplicationConfig] with the provided [dianaConfig] and [globalPipeline].
  ApplicationConfig();
}
