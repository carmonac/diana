import 'dart:typed_data';

class FileData {
  final String filename;
  final Uint8List content;
  final String contentType;
  final int size;

  FileData({
    required this.filename,
    required this.content,
    required this.contentType,
    required this.size,
  });
}
