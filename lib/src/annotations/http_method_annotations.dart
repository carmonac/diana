abstract class BaseHttpMethodAnnotation {
  final String method;
  final String? path;

  const BaseHttpMethodAnnotation(this.method, this.path);
}

class Get extends BaseHttpMethodAnnotation {
  const Get([String path = '/']) : super('GET', path);
}

class Post extends BaseHttpMethodAnnotation {
  const Post([String path = '/']) : super('POST', path);
}

class Put extends BaseHttpMethodAnnotation {
  const Put([String path = '/']) : super('PUT', path);
}

class Delete extends BaseHttpMethodAnnotation {
  const Delete([String path = '/']) : super('DELETE', path);
}

class Patch extends BaseHttpMethodAnnotation {
  const Patch([String path = '/']) : super('PATCH', path);
}
