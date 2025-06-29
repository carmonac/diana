import 'package:diana/src/addons/contenttypes/html_content_type.dart';

import '../addons/contenttypes/form_url_enconde_content_type.dart';
import '../addons/contenttypes/formdata_content_type.dart';
import '../addons/contenttypes/json_content_type.dart';
import '../addons/contenttypes/octet_stream_content_type.dart';
import '../addons/contenttypes/plain_text_content_type.dart';
import '../addons/contenttypes/xml_content_type.dart';
import 'base/base.dart';

class ContentTypeRegistry {
  // Map initialized with default contentTypeControllers
  static final Map<String, ContentType> contentTypeControllers = {
    'application/x-www-form-urlencoded': FormUrlEncondeContentType(),
    'multipart/form-data': FormdataContentType(),
    'application/json': JsonContentType(),
    'application/octet-stream': OctetStreamContentType(),
    'text/plain': PlainTextContentType(),
    'application/xml': XmlContentType(),
    'text/xml': XmlContentType(),
    'text/html': HtmlContentType(),
  };

  static void registerContentTypeObject<T extends ContentType>(T ctype) {
    for (String contentTypeDesc in ctype.contentType) {
      contentTypeControllers[contentTypeDesc] = ctype;
    }
  }

  static ContentType? getContentTypeHandler(String contentType) {
    return contentTypeControllers[contentType] ??
        contentTypeControllers['text/plain'];
  }
}
