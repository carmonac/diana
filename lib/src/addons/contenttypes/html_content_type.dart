import 'package:diana/diana.dart';

/// In case you want to return a html (for example a jinja template file generated, this class should be used)
/// For other types like text/css or application/javascipr, use static folder.
@ContentTypeSerializer(['text/html', 'application/xhtml+xml'])
class HtmlContentType extends ContentType with Serializable {
  HtmlContentType(super.contentType);

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
