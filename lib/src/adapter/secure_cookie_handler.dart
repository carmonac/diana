import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:shelf/shelf.dart';

/// Configuration for a cookie
class CookieData {
  final String value;
  final bool encrypt;
  final int? maxAge;
  final String? domain;
  final String? path;
  final bool secure;
  final bool httpOnly;
  final String? sameSite;

  const CookieData({
    required this.value,
    this.encrypt = false,
    this.maxAge,
    this.domain,
    this.path = '/',
    this.secure = true,
    this.httpOnly = true,
    this.sameSite = 'Strict',
  });
}

/// A secure cookie handler that encrypts and signs cookie values
class SecureCookieHandler {
  final String _secretKey;
  final Random _random = Random.secure();

  SecureCookieHandler(this._secretKey) {
    if (_secretKey.length < 32) {
      throw ArgumentError('Secret key must be at least 32 characters long');
    }
  }

  /// Creates a middleware that adds secure cookie functionality to requests
  Middleware get middleware {
    return (Handler innerHandler) {
      return (Request request) async {
        final modifiedRequest = request.change(
          context: {'cookie_handler': this, ...request.context},
        );
        return await innerHandler(modifiedRequest);
      };
    };
  }

  /// Parse cookie header string into a map
  Map<String, String> _parseCookies(Request request) {
    final cookies = <String, String>{};
    final cookieHeader = request.headers['cookie'];

    if (cookieHeader == null || cookieHeader.isEmpty) {
      return cookies;
    }

    final parts = cookieHeader.split(';');
    for (final part in parts) {
      final trimmed = part.trim();
      final equalIndex = trimmed.indexOf('=');
      if (equalIndex > 0) {
        final name = trimmed.substring(0, equalIndex).trim();
        final value = trimmed.substring(equalIndex + 1).trim();
        cookies[name] = Uri.decodeComponent(value);
      }
    }
    return cookies;
  }

  /// Get a plain cookie value
  String? getCookie(Request request, String name) {
    final cookies = _parseCookies(request);
    return cookies[name];
  }

  /// Get an encrypted cookie value and decrypt it
  String? getEncryptedCookie(Request request, String name) {
    final encryptedValue = getCookie(request, name);
    if (encryptedValue == null) {
      return null;
    }

    try {
      return _decrypt(encryptedValue);
    } catch (e) {
      print('Failed to decrypt cookie "$name": $e');
      return null;
    }
  }

  /// SOLUCION AL PROBLEMA: Set multiple cookies at once
  Response setAllCookies(Response response, Map<String, CookieData> cookies) {
    final cookieHeaders = <String>[];

    for (final entry in cookies.entries) {
      final name = entry.key;
      final data = entry.value;

      String value;
      if (data.encrypt) {
        value = _encrypt(data.value);
      } else {
        value = data.value;
      }

      final cookieHeader = _buildCookieHeader(
        name,
        value,
        maxAge: data.maxAge,
        domain: data.domain,
        path: data.path,
        secure: data.secure,
        httpOnly: data.httpOnly,
        sameSite: data.sameSite,
      );

      cookieHeaders.add(cookieHeader);
    }

    print('Setting ${cookieHeaders.length} cookies at once');

    final newHeaders = Map<String, Object>.from(response.headers);
    newHeaders['set-cookie'] = cookieHeaders;

    return response.change(headers: newHeaders);
  }

  /// Encrypt a value using simple encryption with HMAC signature
  String _encrypt(String plaintext) {
    final iv = Uint8List(16);
    for (int i = 0; i < iv.length; i++) {
      iv[i] = _random.nextInt(256);
    }

    final keyBytes = utf8.encode(_secretKey).take(32).toList();
    final plaintextBytes = utf8.encode(plaintext);
    final encrypted = Uint8List(plaintextBytes.length);

    for (int i = 0; i < plaintextBytes.length; i++) {
      encrypted[i] =
          plaintextBytes[i] ^ keyBytes[i % keyBytes.length] ^ iv[i % iv.length];
    }

    final combined = Uint8List(iv.length + encrypted.length);
    combined.setRange(0, iv.length, iv);
    combined.setRange(iv.length, combined.length, encrypted);

    final hmacKey = utf8.encode(_secretKey);
    final hmac = Hmac(sha256, hmacKey);
    final signature = hmac.convert(combined);

    final finalData = Uint8List(signature.bytes.length + combined.length);
    finalData.setRange(0, signature.bytes.length, signature.bytes);
    finalData.setRange(signature.bytes.length, finalData.length, combined);

    return base64Url.encode(finalData);
  }

  /// Decrypt a value and verify HMAC signature
  String _decrypt(String encryptedData) {
    final data = base64Url.decode(encryptedData);

    final signature = data.sublist(0, 32);
    final combined = data.sublist(32);

    final hmacKey = utf8.encode(_secretKey);
    final hmac = Hmac(sha256, hmacKey);
    final expectedSignature = hmac.convert(combined);

    if (!_constantTimeEquals(signature, expectedSignature.bytes)) {
      throw Exception('Invalid signature');
    }

    final iv = combined.sublist(0, 16);
    final encrypted = combined.sublist(16);

    final keyBytes = utf8.encode(_secretKey).take(32).toList();
    final decrypted = Uint8List(encrypted.length);

    for (int i = 0; i < encrypted.length; i++) {
      decrypted[i] =
          encrypted[i] ^ keyBytes[i % keyBytes.length] ^ iv[i % iv.length];
    }

    return utf8.decode(decrypted);
  }

  /// Constant time comparison to prevent timing attacks
  bool _constantTimeEquals(List<int> a, List<int> b) {
    if (a.length != b.length) return false;

    int result = 0;
    for (int i = 0; i < a.length; i++) {
      result |= a[i] ^ b[i];
    }
    return result == 0;
  }

  /// Build cookie header string
  String _buildCookieHeader(
    String name,
    String value, {
    int? maxAge,
    String? domain,
    String? path,
    bool? secure,
    bool? httpOnly,
    String? sameSite,
  }) {
    final parts = <String>['$name=${Uri.encodeComponent(value)}'];

    if (maxAge != null) {
      parts.add('Max-Age=$maxAge');
    }
    if (domain != null) {
      parts.add('Domain=$domain');
    }
    if (path != null) {
      parts.add('Path=$path');
    }
    if (secure == true) {
      parts.add('Secure');
    }
    if (httpOnly == true) {
      parts.add('HttpOnly');
    }
    if (sameSite != null) {
      parts.add('SameSite=$sameSite');
    }

    return parts.join('; ');
  }
}
