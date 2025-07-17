import 'package:diana/src/http/interfaces.dart';
import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart';
import 'shelf_request_adapter.dart';
import 'shelf_response_adapter.dart';

class ShelfHttpAdapter implements DianaServer {
  final Router _router = Router();
  final shelf.Pipeline _pipeline = shelf.Pipeline();

  @override
  Future<void> start(String host, int port) async {
    await io.serve(_pipeline.addHandler(_router.call), host, port);
  }

  @override
  void addRoute(String method, String path, DianaHandler handler) {
    _router.add(method, path, (shelf.Request request) async {
      final dianaRequest = ShelfRequestAdapter(request);
      final dianaResponse = await handler(dianaRequest);
      return (dianaResponse as ShelfResponseAdapter).shelfResponse;
    });
  }

  @override
  void addMiddleware(DianaMiddleware middleware) {
    // TODO: implement addMiddleware
  }

  @override
  Future<void> stop() {
    // TODO: implement stop
    throw UnimplementedError();
  }
}
