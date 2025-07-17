import 'dart:io';

import 'package:diana/src/core/base/abstract_error_handler.dart';
import 'package:diana/src/core/http_lib.dart';

import 'session_config.dart';

import 'exceptions/diana_http_exception.dart';

class DianaConfig {
  final AbstractErrorHandler? errorHandler;
  final String prefix;
  final DianaHttpErrorBuilder? errorBuilder;
  final SecurityContext? securityContext;
  final bool? redirectTrailingSlash;
  final bool? redirectHttpToHttps;
  final bool? cookieParserEnabled;
  final String defaultOutputContentType;
  final String cookieSecret;
  final SessionConfig? sessionConfig;
  final HttpLib httpLib;

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
    this.httpLib = HttpLib.shelf,
  });
}
