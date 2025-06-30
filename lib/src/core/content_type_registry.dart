import 'package:diana/src/addons/contenttypes/html_content_type.dart';

import '../addons/contenttypes/form_url_enconde_content_type.dart';
import '../addons/contenttypes/formdata_content_type.dart';
import '../addons/contenttypes/json_content_type.dart';
import '../addons/contenttypes/octet_stream_content_type.dart';
import '../addons/contenttypes/plain_text_content_type.dart';
import '../addons/contenttypes/xml_content_type.dart';
import 'base/base.dart';

class ContentTypeRegistry {
  static final List<ContentType> _preLoadedContentTypes = [
    FormUrlEncondeContentType(),
    FormdataContentType(),
    JsonContentType(),
    OctetStreamContentType(),
    PlainTextContentType(),
    XmlContentType(),
    HtmlContentType(),
  ];

  /// Initializes the registry with pre-loaded content types.
  static void initialize() {
    for (ContentType contentType in _preLoadedContentTypes) {
      registerContentTypeObject(contentType);
    }
  }

  // Map initialized with default contentTypeControllers
  static final Map<String, ContentType> contentTypeControllers = {};

  static void registerContentTypeObject<T extends ContentType>(T ctype) {
    for (String contentTypeDesc in ctype.contentType) {
      contentTypeControllers[contentTypeDesc] = ctype;
    }
  }

  static ContentType? getContentTypeHandler(String contentType) {
    final key = _parseAcceptHeader(contentType) ?? contentType;
    return contentTypeControllers[key] ?? contentTypeControllers['text/plain'];
  }

  static String? _parseAcceptHeader(String acceptHeader) {
    final acceptTypes = acceptHeader.split(',');

    for (final type in acceptTypes) {
      final cleanType = type.split(';')[0].trim();
      if (cleanType.isNotEmpty && cleanType != '*/*') {
        return cleanType.toLowerCase();
      }
    }

    return null;
  }
}
