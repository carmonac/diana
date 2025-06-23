import 'dart:convert';
import 'package:shelf/shelf.dart' as shelf;

/// Diana framework HTTP response abstraction
class DianaResponse {
  final shelf.Response _shelfResponse;

  DianaResponse._(this._shelfResponse);

  /// Factory constructor from Shelf response
  factory DianaResponse.fromShelf(shelf.Response response) =>
      DianaResponse._(response);

  /// Create a successful response
  factory DianaResponse.ok(
    Object? body, {
    Map<String, String>? headers,
    String? contentType,
  }) {
    final responseHeaders = <String, String>{
      if (contentType != null) 'content-type': contentType,
      ...?headers,
    };

    return DianaResponse._(
      shelf.Response.ok(
        body,
        headers: responseHeaders.isNotEmpty ? responseHeaders : null,
      ),
    );
  }

  /// Create a JSON response
  factory DianaResponse.json(
    Object? data, {
    int statusCode = 200,
    Map<String, String>? headers,
  }) {
    return DianaResponse._(
      shelf.Response(
        statusCode,
        body: data != null ? json.encode(data) : null,
        headers: {'content-type': 'application/json', ...?headers},
      ),
    );
  }

  /// Create a text response
  factory DianaResponse.text(
    String body, {
    int statusCode = 200,
    Map<String, String>? headers,
  }) {
    return DianaResponse._(
      shelf.Response(
        statusCode,
        body: body,
        headers: {'content-type': 'text/plain', ...?headers},
      ),
    );
  }

  /// Create a redirect response
  factory DianaResponse.redirect(
    String location, {
    int statusCode = 302,
    Map<String, String>? headers,
  }) {
    final responseHeaders = <String, String>{'location': location, ...?headers};
    return DianaResponse._(
      shelf.Response(
        statusCode,
        headers: responseHeaders.isNotEmpty ? responseHeaders : null,
      ),
    );
  }

  /// Create a no content response
  factory DianaResponse.noContent({Map<String, String>? headers}) {
    return DianaResponse._(shelf.Response(204, headers: headers));
  }

  /// Create a xml response
  factory DianaResponse.xml(
    Object? data, {
    int statusCode = 200,
    Map<String, String>? headers,
  }) {
    return DianaResponse._(
      shelf.Response(
        statusCode,
        body: data != null ? _convertToXml(data) : null,
        headers: {'content-type': 'application/xml', ...?headers},
      ),
    );
  }

  /// Create a custom response
  factory DianaResponse(
    int statusCode, {
    Object? body,
    Map<String, String>? headers,
  }) {
    return DianaResponse._(
      shelf.Response(statusCode, body: body, headers: headers),
    );
  }

  /// Create a not found response
  factory DianaResponse.notFound([String? message]) {
    return DianaResponse._(shelf.Response.notFound(message));
  }

  /// Create an internal server error response
  factory DianaResponse.internalServerError([String? message]) {
    return DianaResponse._(shelf.Response.internalServerError(body: message));
  }

  /// Response status code
  int get statusCode => _shelfResponse.statusCode;

  /// Response headers
  Map<String, String> get headers => _shelfResponse.headers;

  /// Internal shelf response (for framework internal use only)
  shelf.Response get shelfResponse => _shelfResponse;

  /// Convert data to XML string
  static String _convertToXml(Object data) {
    if (data is String) {
      // Si ya es un string, asumimos que es XML válido
      return data;
    } else if (data is Map<String, dynamic>) {
      // Convertir Map a XML básico
      return _mapToXml(data);
    } else if (data is List) {
      // Convertir List a XML básico
      return _listToXml(data);
    } else {
      // Para otros tipos, wrap en un elemento raíz
      return '<root>${_escapeXml(data.toString())}</root>';
    }
  }

  /// Convert Map to XML
  static String _mapToXml(
    Map<String, dynamic> map, {
    String rootElement = 'root',
  }) {
    final buffer = StringBuffer();
    buffer.write('<$rootElement>');

    map.forEach((key, value) {
      final safeKey = _sanitizeXmlElementName(key);
      buffer.write('<$safeKey>');

      if (value is Map<String, dynamic>) {
        buffer.write(_mapToXml(value, rootElement: 'item'));
      } else if (value is List) {
        buffer.write(_listToXml(value));
      } else {
        buffer.write(_escapeXml(value?.toString() ?? ''));
      }

      buffer.write('</$safeKey>');
    });

    buffer.write('</$rootElement>');
    return buffer.toString();
  }

  /// Convert List to XML
  static String _listToXml(List list) {
    final buffer = StringBuffer();

    for (int i = 0; i < list.length; i++) {
      buffer.write('<item>');

      if (list[i] is Map<String, dynamic>) {
        buffer.write(_mapToXml(list[i], rootElement: 'entry'));
      } else if (list[i] is List) {
        buffer.write(_listToXml(list[i]));
      } else {
        buffer.write(_escapeXml(list[i]?.toString() ?? ''));
      }

      buffer.write('</item>');
    }

    return buffer.toString();
  }

  /// Escape XML special characters
  static String _escapeXml(String text) {
    return text
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&apos;');
  }

  /// Sanitize XML element names (remove invalid characters)
  static String _sanitizeXmlElementName(String name) {
    // Remover caracteres no válidos para nombres de elementos XML
    return name.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
  }
}
