class StaticOptions {
  final String path;
  final String? defaultDocument;
  final bool listDirectory;
  const StaticOptions({
    required this.path,
    this.defaultDocument,
    this.listDirectory = false,
  });
}
