class Static {
  final String path;
  final String? defaultDocument;
  final bool listDirectory;
  const Static({
    required this.path,
    this.defaultDocument,
    this.listDirectory = false,
  });
}
