import 'package:diana/src/core/base/base.dart';

enum VersionType {
  /// Represents a version extracted from the request path.
  path,

  /// Represents a version extracted from the request header.
  header,

  /// Represents a version extracted from the request query parameters.
  query,

  /// Represents a version extracted from the media type.
  mediaType,

  /// Represents a version extracted in a custom way.
  custom,
}

class Version {
  /// The version value.
  final String? key;
  AbstractVersionExtractor? extractor;

  /// The type of the version.
  final VersionType type;

  /// Creates a new [Version] instance.
  Version(this.type, {this.key, this.extractor});

  // set the extractor for the version
  void setExtractor(AbstractVersionExtractor extractor) {
    this.extractor = extractor;
  }
}
