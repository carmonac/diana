import 'package:diana/diana.dart';

/// In case you want to return a html (for example a jinja template file generated, this class should be used)
/// For other types like text/css or application/javascipr, use static folder.
class HtmlContentType with Serializable implements ContentType {
  @override
  List<String> get contentType => ['text/html'];

  @override
  dynamic serialize(object) {
    try {
      if (object is! String) {
        return object.toString();
      }
      return object;
    } catch (e) {
      throw BadRequestException('Invalid HTML body: $e');
    }
  }
}
