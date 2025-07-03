abstract class BaseHttpMethodAnnotation {
  final String method;
  final String path;
  final String? description;
  final int defaultStatusCode;

  const BaseHttpMethodAnnotation({
    required this.method,
    required this.path,
    this.description,
    required this.defaultStatusCode,
  });
}

class Get extends BaseHttpMethodAnnotation {
  const Get({super.path = '', super.description, super.defaultStatusCode = 200})
    : super(method: 'GET');
}

class Post extends BaseHttpMethodAnnotation {
  const Post({
    super.path = '',
    super.description,
    super.defaultStatusCode = 201,
  }) : super(method: 'POST');
}

class Put extends BaseHttpMethodAnnotation {
  const Put({super.path = '', super.description, super.defaultStatusCode = 200})
    : super(method: 'PUT');
}

class Delete extends BaseHttpMethodAnnotation {
  const Delete({
    super.path = '',
    super.description,
    super.defaultStatusCode = 204,
  }) : super(method: 'DELETE');
}

class Patch extends BaseHttpMethodAnnotation {
  const Patch({
    super.path = '',
    super.description,
    super.defaultStatusCode = 200,
  }) : super(method: 'PATCH');
}
