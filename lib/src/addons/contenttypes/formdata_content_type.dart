import 'dart:convert';
import 'dart:typed_data';

import 'package:diana/diana.dart';

class FormdataContentType with Deserializable implements ContentType {
  @override
  List<String> get contentType => ['multipart/form-data'];

  @override
  Future<dynamic> deserialize(DianaRequest request, Type type) async {
    try {
      final contentType = request.contentType ?? '';
      final boundary = _extractBoundary(contentType);

      if (boundary == null) {
        throw BadRequestException('Missing boundary in multipart/form-data');
      }

      final bodyBytes = await request.readAsBytes();
      final formData = await _parseMultipartData(
        Uint8List.fromList(bodyBytes),
        boundary,
      );

      if (DtoRegistry.isRegistered(type)) {
        return DtoRegistry.deserializeByType(formData, type);
      } else if (type == String) {
        return formData.toString();
      } else if (type == Map<String, dynamic>) {
        return formData;
      }

      // Fallback for unsupported types
      return formData;
    } catch (e) {
      throw BadRequestException('Invalid multipart/form-data body: $e');
    }
  }

  String? _extractBoundary(String contentType) {
    final boundaryMatch = RegExp(
      r'boundary=([^;,\s]+)',
    ).firstMatch(contentType);
    return boundaryMatch?.group(1)?.replaceAll('"', '');
  }

  Future<Map<String, dynamic>> _parseMultipartData(
    Uint8List bodyBytes,
    String boundary,
  ) async {
    final formData = <String, dynamic>{};
    final boundaryBytes = utf8.encode('--$boundary');

    // Find all boundary positions
    final boundaryPositions = <int>[];
    for (int i = 0; i <= bodyBytes.length - boundaryBytes.length; i++) {
      if (_bytesEqual(bodyBytes, i, boundaryBytes)) {
        boundaryPositions.add(i);
      }
    }

    // Process each part between boundaries
    for (int i = 0; i < boundaryPositions.length - 1; i++) {
      final startPos = boundaryPositions[i] + boundaryBytes.length;
      final endPos = boundaryPositions[i + 1];

      if (startPos >= endPos) continue;

      var partBytes = bodyBytes.sublist(startPos, endPos);

      // Skip leading \r\n
      if (partBytes.length >= 2 && partBytes[0] == 13 && partBytes[1] == 10) {
        partBytes = partBytes.sublist(2);
      }

      // Skip trailing \r\n
      if (partBytes.length >= 2 &&
          partBytes[partBytes.length - 2] == 13 &&
          partBytes[partBytes.length - 1] == 10) {
        partBytes = partBytes.sublist(0, partBytes.length - 2);
      }

      await _processPart(partBytes, formData);
    }

    return formData;
  }

  bool _bytesEqual(Uint8List source, int offset, List<int> pattern) {
    if (offset + pattern.length > source.length) return false;
    for (int i = 0; i < pattern.length; i++) {
      if (source[offset + i] != pattern[i]) return false;
    }
    return true;
  }

  Future<void> _processPart(
    Uint8List partBytes,
    Map<String, dynamic> formData,
  ) async {
    // Find header/body separation (\r\n\r\n)
    int headerEnd = -1;
    for (int i = 0; i < partBytes.length - 3; i++) {
      if (partBytes[i] == 13 &&
          partBytes[i + 1] == 10 &&
          partBytes[i + 2] == 13 &&
          partBytes[i + 3] == 10) {
        headerEnd = i;
        break;
      }
    }

    if (headerEnd == -1) return;

    final headerBytes = partBytes.sublist(0, headerEnd);
    final contentBytes = partBytes.sublist(headerEnd + 4);

    final headers = utf8.decode(headerBytes);
    final fieldName = _extractFieldName(headers);
    final fileName = _extractFileName(headers);
    final contentType = _extractContentType(headers);

    if (fieldName == null) return;

    if (fileName != null && fileName.isNotEmpty) {
      formData[fieldName] = FileData(
        filename: fileName,
        content: contentBytes,
        contentType: contentType ?? 'application/octet-stream',
        size: contentBytes.length,
      );
    } else {
      // Text field
      final textValue = utf8.decode(contentBytes).trim();
      formData[fieldName] = textValue;
    }
  }

  String? _extractFieldName(String headers) {
    final match = RegExp(
      r'name\s*=\s*"([^"]+)"',
      caseSensitive: false,
    ).firstMatch(headers);
    return match?.group(1);
  }

  String? _extractFileName(String headers) {
    final match = RegExp(
      r'filename\s*=\s*"([^"]*)"',
      caseSensitive: false,
    ).firstMatch(headers);
    return match?.group(1);
  }

  String? _extractContentType(String headers) {
    final match = RegExp(
      r'Content-Type\s*:\s*([^\r\n]+)',
      caseSensitive: false,
    ).firstMatch(headers);
    return match?.group(1)?.trim();
  }
}
