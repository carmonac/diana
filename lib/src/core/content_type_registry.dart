import 'base/base.dart';

class ContentTypeRegistry {
  // Map initialized with default contentTypeControllers
  static final Map<String, ContentType> contentTypeControllers = {};

  static void registerContentTypeObject<T extends ContentType>(T ctype) {
    for (String contentTypeDesc in ctype.contentTypes) {
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
