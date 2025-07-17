import 'package:diana/src/core/service_locator.dart';
import 'package:diana/src/http/interfaces.dart';

class DianaAdapter {
  final DianaServer _DianaServer;
  final ServiceLocator _serviceLocator;

  DianaAdapter(this._DianaServer, this._serviceLocator);

  Future<void> start({String? host, int? port}) async {
    // TODO: Implement global middleware setup if needed
    // _setupGlobalMiddleware();
    _setupRoutes();
    await _DianaServer.start(host ?? 'localhost', port ?? 8080);
  }

  void _setupRoutes() {
    // Framework-agnostic route setup
    // TODO: Implement route setup logic
    // for (final route in _serviceLocator.routes) {
    //   _DianaServer.addRoute(route.method, route.path, _createHandler(route));
    // }
  }
}
