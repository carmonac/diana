import 'dart:typed_data';

import 'package:diana/diana.dart';

@ContentTypeSerializer(['application/octet-stream'])
class OctetStreamContentType extends ContentType
    with Deserializable, Serializable {
  OctetStreamContentType(super.contentTypes);

  @override
  Future<dynamic> deserialize(DianaRequest request, Type type) async {
    final bytesBuilder = BytesBuilder(copy: false);
    await for (final chunk in request.read()) {
      bytesBuilder.add(chunk);
    }

    final contentBytes = bytesBuilder.takeBytes();

    if (contentBytes.isEmpty) {
      throw BadRequestException('Empty body for application/octet-stream');
    }

    // final bodyBytes = await request.readAsBytes();
    // if (bodyBytes.isEmpty) {
    //   throw BadRequestException('Empty body for application/octet-stream');
    // }
    // // Convert List<int> to Uint8List
    // final contentBytes = Uint8List.fromList(bodyBytes);

    // Extract filename from headers (could be Content-Disposition)
    final filename = request.header('content-disposition') != null
        ? _extractFilename(request.header('content-disposition')!)
        : 'file';

    final fileData = FileData(
      filename: filename,
      contentType: request.contentType ?? 'application/octet-stream',
      content: contentBytes,
      size: contentBytes.length,
    );

    return fileData;
  }

  @override
  dynamic serialize(dynamic object) {
    if (object is FileData) {
      return object.content;
    }

    if (object is Uint8List) {
      return object;
    }

    if (object is List<int>) {
      return Uint8List.fromList(object);
    }

    throw BadRequestException(
      'Cannot serialize object of type ${object.runtimeType} to octet-stream',
    );
  }

  String _extractFilename(String contentDisposition) {
    final match = RegExp(
      r'filename\s*=\s*"([^"]+)"',
      caseSensitive: false,
    ).firstMatch(contentDisposition);
    return match?.group(1) ?? 'file';
  }
}
