import 'package:shelf/shelf.dart';

abstract class AbstractShelfMiddleware {
  Middleware adapter();
}
