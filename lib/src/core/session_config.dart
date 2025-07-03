/// Configuration for session storage
class SessionConfig {
  final String cookieName;
  final int maxAge;
  final String? domain;
  final String? path;
  final bool secure;
  final bool httpOnly;
  final String? sameSite;

  const SessionConfig({
    this.cookieName = 'session_id',
    this.maxAge = 86400, // 24 hours by default
    this.domain,
    this.path = '/',
    this.secure = false,
    this.httpOnly = true,
    this.sameSite = 'Strict',
  });
}
