import 'dart:io';

import 'session_config.dart';

import 'base/base.dart';

import 'exceptions/diana_http_exception.dart';

class DianaConfig {
  final DianaErrorHandler? errorHandler;
  final String prefix;
  final DianaHttpErrorBuilder? errorBuilder;
  final SecurityContext? securityContext;
  final bool? redirectTrailingSlash;
  final bool? redirectHttpToHttps;
  final bool? cookieParserEnabled;
  final String defaultOutputContentType;
  final String cookieSecret;
  final SessionConfig? sessionConfig;

  DianaConfig({
    this.errorHandler,
    this.prefix = '',
    this.errorBuilder,
    this.securityContext,
    this.redirectTrailingSlash,
    this.redirectHttpToHttps,
    this.cookieParserEnabled = false,
    this.defaultOutputContentType = 'application/json',
    this.cookieSecret = '12345678901234567890123456789012',
    this.sessionConfig,
  });
}
