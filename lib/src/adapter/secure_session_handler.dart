import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:shelf/shelf.dart';
import '../core/session_config.dart';

/// Session data container
class SessionData {
  final Map<String, dynamic> _data = {};
  bool _isModified = false;
  String? _sessionId;

  /// Get a value from the session
  T? get<T>(String key) {
    return _data[key] as T?;
  }

  /// Set a value in the session
  void set<T>(String key, T value) {
    _data[key] = value;
    _isModified = true;
  }

  /// Remove a value from the session
  void remove(String key) {
    _data.remove(key);
    _isModified = true;
  }

  /// Clear all session data
  void clear() {
    _data.clear();
    _isModified = true;
  }

  /// Check if session contains a key
  bool containsKey(String key) {
    return _data.containsKey(key);
  }

  /// Get all keys
  Iterable<String> get keys => _data.keys;

  /// Check if session was modified
  bool get isModified => _isModified;

  /// Get session data as map
  Map<String, dynamic> toMap() => Map.from(_data);

  /// Load data from map
  void fromMap(Map<String, dynamic> data) {
    _data.clear();
    _data.addAll(data);
    _isModified = false;
  }

  /// Get session ID
  String? get sessionId => _sessionId;

  /// Set session ID (internal use)
  void _setSessionId(String? id) {
    _sessionId = id;
  }

  /// Mark session as saved (internal use)
  void _markAsSaved() {
    _isModified = false;
  }
}

/// A secure session handler that encrypts and signs session data
class SecureSessionHandler {
  final String _secretKey;
  final SessionConfig _config;
  final Random _random = Random.secure();
  final Map<String, SessionData> _sessions = {};

  SecureSessionHandler(
    this._secretKey, {
    SessionConfig config = const SessionConfig(),
  }) : _config = config {
    if (_secretKey.length < 32) {
      throw ArgumentError('Secret key must be at least 32 characters long');
    }
  }

  /// Creates a middleware that adds session functionality to requests
  Middleware get middleware {
    return (Handler innerHandler) {
      return (Request request) async {
        // Get or create session
        final sessionData = _getOrCreateSession(request);

        // Add session to request context
        final modifiedRequest = request.change(
          context: {
            'session': sessionData,
            // 'session_handler': this,
            ...request.context,
          },
        );

        // Process request
        final response = await innerHandler(modifiedRequest);

        // Save session if modified
        return _saveSessionIfNeeded(response, sessionData);
      };
    };
  }

  /// Get session from request context
  static SessionData? getSession(Request request) {
    return request.context['session'] as SessionData?;
  }

  /// Get or create a session for the request
  SessionData _getOrCreateSession(Request request) {
    final sessionId = _getSessionId(request);

    if (sessionId != null && _sessions.containsKey(sessionId)) {
      final session = _sessions[sessionId]!;
      session._setSessionId(sessionId);
      return session;
    }

    // Create new session
    final newSession = SessionData();
    // Don't set sessionId yet - it will be generated when saving if needed
    return newSession;
  }

  /// Get session ID from request cookie
  String? _getSessionId(Request request) {
    final cookieHeader = request.headers['cookie'];

    if (cookieHeader == null || cookieHeader.isEmpty) {
      return null;
    }

    final cookies = _parseCookies(cookieHeader);
    final encryptedSessionId = cookies[_config.cookieName];

    if (encryptedSessionId == null) {
      return null;
    }

    try {
      final sessionData = _decrypt(encryptedSessionId);
      final decoded = jsonDecode(sessionData) as Map<String, dynamic>;

      // Check expiration
      final expiresAt = decoded['expires_at'] as int?;
      if (expiresAt != null &&
          DateTime.now().millisecondsSinceEpoch > expiresAt) {
        return null;
      }

      final sessionId = decoded['session_id'] as String;
      return sessionId;
    } catch (e) {
      print('Failed to decrypt session ID: $e');
      return null;
    }
  }

  /// Save session if it was modified
  Response _saveSessionIfNeeded(Response response, SessionData session) {
    // If session is not modified and not empty, don't save
    if (!session.isModified && session.toMap().isNotEmpty) {
      return response;
    }

    // If session is empty, clear the cookie
    if (session.toMap().isEmpty) {
      return _clearSessionCookie(response);
    }

    // Get existing session ID or generate a new one
    String sessionId = session.sessionId ?? _generateSessionId();

    // Store session with the ID
    _sessions[sessionId] = session;
    session._setSessionId(sessionId);
    session._markAsSaved();

    // Create session cookie data
    final sessionCookieData = {
      'session_id': sessionId,
      'expires_at': DateTime.now()
          .add(Duration(seconds: _config.maxAge))
          .millisecondsSinceEpoch,
    };

    final encryptedSessionData = _encrypt(jsonEncode(sessionCookieData));

    return _setSessionCookie(response, encryptedSessionData);
  }

  /// Generate a new session ID
  String _generateSessionId() {
    final bytes = Uint8List(32);
    for (int i = 0; i < bytes.length; i++) {
      bytes[i] = _random.nextInt(256);
    }
    return base64Url.encode(bytes);
  }

  /// Set session cookie in response
  Response _setSessionCookie(Response response, String sessionData) {
    final cookieValue = _buildCookieHeader(
      _config.cookieName,
      sessionData,
      maxAge: _config.maxAge,
      domain: _config.domain,
      path: _config.path,
      secure: _config.secure,
      httpOnly: _config.httpOnly,
      sameSite: _config.sameSite,
    );

    final newHeaders = Map<String, Object>.from(response.headers);
    final existingCookies = newHeaders['set-cookie'];

    if (existingCookies is List) {
      newHeaders['set-cookie'] = [...existingCookies, cookieValue];
    } else if (existingCookies is String) {
      newHeaders['set-cookie'] = [existingCookies, cookieValue];
    } else {
      newHeaders['set-cookie'] = [cookieValue];
    }

    return response.change(headers: newHeaders);
  }

  /// Clear session cookie
  Response _clearSessionCookie(Response response) {
    final cookieValue = _buildCookieHeader(
      _config.cookieName,
      '',
      maxAge: 0,
      domain: _config.domain,
      path: _config.path,
      secure: _config.secure,
      httpOnly: _config.httpOnly,
      sameSite: _config.sameSite,
    );

    final newHeaders = Map<String, Object>.from(response.headers);
    final existingCookies = newHeaders['set-cookie'];

    if (existingCookies is List) {
      newHeaders['set-cookie'] = [...existingCookies, cookieValue];
    } else if (existingCookies is String) {
      newHeaders['set-cookie'] = [existingCookies, cookieValue];
    } else {
      newHeaders['set-cookie'] = [cookieValue];
    }

    return response.change(headers: newHeaders);
  }

  /// Clean up expired sessions
  void cleanupExpiredSessions() {
    // In a real implementation, you'd store session expiration timestamps
    // and remove expired sessions. For now, this is a placeholder.
    // You can implement proper session expiration logic as needed.
  }

  // Utility methods (similar to SecureCookieHandler)
  Map<String, String> _parseCookies(String cookieHeader) {
    final cookies = <String, String>{};
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

  bool _constantTimeEquals(List<int> a, List<int> b) {
    if (a.length != b.length) return false;

    int result = 0;
    for (int i = 0; i < a.length; i++) {
      result |= a[i] ^ b[i];
    }
    return result == 0;
  }

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
