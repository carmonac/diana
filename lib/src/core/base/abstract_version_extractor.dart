import 'package:diana/src/http/interfaces.dart';

abstract class AbstractVersionExtractor {
  /// Extracts the version from the given [version] based.
  ///
  /// Returns a [String] containing the value of the version.
  String extract(DianaRequest version);
}
