import 'package:diana/diana.dart';

class PlainTextContentType
    with Serializable, Deserializable
    implements ContentType {
  @override
  List<String> get contentType => ['text/plain'];

  @override
  Future<dynamic> deserialize(DianaRequest request, Type type) async {
    if (type == String) {
      final bodyString = await request.readAsString();
      return bodyString.isEmpty ? null : bodyString;
    } else if (type == int) {
      final bodyString = await request.readAsString();
      return int.tryParse(bodyString) ?? 0;
    } else if (type == double) {
      final bodyString = await request.readAsString();
      return double.tryParse(bodyString) ?? 0.0;
    } else if (type == bool) {
      final bodyString = await request.readAsString();
      return bodyString.toLowerCase() == 'true';
    }
  }

  @override
  serialize(object) {
    if (object == null) {
      return '';
    }
    if (object is String || object is num || object is bool) {
      return object.toString();
    }
    if (object is List) {
      return object.map((e) => e.toString()).join('\n');
    }
    if (object is Map) {
      return object.entries
          .map((entry) => '${entry.key}: ${entry.value}')
          .join('\n');
    }
    throw BadRequestException(
      'Cannot serialize object of type ${object.runtimeType} to plain text',
    );
  }
}
