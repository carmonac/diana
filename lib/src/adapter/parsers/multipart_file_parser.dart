import 'dart:convert';
import 'dart:typed_data';
import 'package:shelf/shelf.dart';
import 'package:http_parser/http_parser.dart';

import '../../core/exceptions/exceptions.dart';
import '../../core/handler_composer.dart';
import '../../core/file_data.dart';

class MultipartFileParser {
  static Future<dynamic> parse(Request request, Parameter param) async {
    try {
      final contentType = request.headers['content-type'];
      if (contentType == null) {
        throw BadRequestException(
          'Content-Type header is required for multipart data',
        );
      }

      final mediaType = MediaType.parse(contentType);
      final boundary = mediaType.parameters['boundary'];

      if (boundary == null) {
        throw BadRequestException(
          'Boundary parameter is required for multipart data',
        );
      }

      final bodyBytes = await request.read().expand((chunk) => chunk).toList();
      final bodyString = utf8.decode(bodyBytes);

      final files = <String, FileData>{};
      final parts = _parseMultipartData(bodyString, boundary);

      for (final part in parts) {
        if (part.filename != null) {
          final fileData = FileData(
            filename: part.filename!,
            contentType: part.contentType,
            data: part.data,
          );
          files[part.name] = fileData;
        }
      }

      // If param has a name, return the specific file
      if (param.name != null) {
        return files[param.name];
      }

      // If no name specified, return all files as a list
      return files.values.toList();
    } catch (e) {
      throw BadRequestException('Invalid multipart/form-data: $e');
    }
  }

  static List<MultipartPart> _parseMultipartData(String body, String boundary) {
    final parts = <MultipartPart>[];
    final boundaryDelimiter = '--$boundary';
    final sections = body.split(boundaryDelimiter);

    for (final section in sections) {
      if (section.trim().isEmpty || section.trim() == '--') continue;

      final headerEndIndex = section.indexOf('\r\n\r\n');
      if (headerEndIndex == -1) continue;

      final headerSection = section.substring(0, headerEndIndex);
      final dataSection = section.substring(headerEndIndex + 4);

      final part = _parseMultipartPart(headerSection, dataSection);
      if (part != null) {
        parts.add(part);
      }
    }

    return parts;
  }

  static MultipartPart? _parseMultipartPart(
    String headerSection,
    String dataSection,
  ) {
    final headers = headerSection.split('\r\n');
    String? name;
    String? filename;
    String? contentType;

    for (final header in headers) {
      if (header.toLowerCase().startsWith('content-disposition:')) {
        final dispositionMatch = RegExp(r'name="([^"]*)"').firstMatch(header);
        if (dispositionMatch != null) {
          name = dispositionMatch.group(1);
        }

        final filenameMatch = RegExp(r'filename="([^"]*)"').firstMatch(header);
        if (filenameMatch != null) {
          filename = filenameMatch.group(1);
        }
      } else if (header.toLowerCase().startsWith('content-type:')) {
        contentType = header.substring('content-type:'.length).trim();
      }
    }

    if (name == null) return null;

    final data = utf8.encode(dataSection.replaceAll(RegExp(r'\r?\n$'), ''));

    return MultipartPart(
      name: name,
      filename: filename,
      contentType: contentType,
      data: data,
    );
  }
}

class MultipartPart {
  final String name;
  final String? filename;
  final String? contentType;
  final Uint8List data;

  MultipartPart({
    required this.name,
    this.filename,
    this.contentType,
    required this.data,
  });
}
