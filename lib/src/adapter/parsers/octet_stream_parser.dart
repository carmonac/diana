import 'dart:typed_data';
import 'package:shelf/shelf.dart';

import '../../core/exceptions/exceptions.dart';
import '../../core/handler_composer.dart';
import '../../core/file_data.dart';

class OctetStreamParser {
  static Future<dynamic> parse(Request request, Parameter param) async {
    try {
      final bodyBytes = await request.read().expand((chunk) => chunk).toList();

      if (bodyBytes.isEmpty) {
        return null;
      }

      final data = Uint8List.fromList(bodyBytes);

      // For octet-stream, we create a generic file data object
      final fileData = FileData(
        filename: param.name ?? 'unknown_file',
        contentType: 'application/octet-stream',
        data: data,
      );

      return fileData;
    } catch (e) {
      throw BadRequestException('Invalid octet-stream data: $e');
    }
  }
}
