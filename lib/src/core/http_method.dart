enum HttpMethod { get, post, put, patch, delete, head, options, trace, connect }

extension HttpMethodsExtension on HttpMethod {
  String get name {
    switch (this) {
      case HttpMethod.get:
        return 'GET';
      case HttpMethod.post:
        return 'POST';
      case HttpMethod.put:
        return 'PUT';
      case HttpMethod.patch:
        return 'PATCH';
      case HttpMethod.delete:
        return 'DELETE';
      case HttpMethod.head:
        return 'HEAD';
      case HttpMethod.options:
        return 'OPTIONS';
      case HttpMethod.trace:
        return 'TRACE';
      case HttpMethod.connect:
        return 'CONNECT';
    }
  }
}
