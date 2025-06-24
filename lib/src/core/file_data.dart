import 'dart:typed_data';

class FileData {
  final String filename;
  final String? contentType;
  final Uint8List data;

  FileData({required this.filename, this.contentType, required this.data});
}
