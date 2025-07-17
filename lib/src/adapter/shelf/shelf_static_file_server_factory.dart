import 'package:diana/src/http/interfaces.dart';
import 'package:shelf/shelf.dart' as shelf;
import 'package:shelf_static/shelf_static.dart';
import 'shelf_request_adapter.dart';
import 'shelf_response_adapter.dart';

class ShelfStaticFileServerFactory implements DianaStaticFileServerFactory {
  @override
  DianaHandler createStaticFileServer(StaticFileServerConfig config) {
    // Create the shelf static handler
    final shelfHandler = createStaticHandler(
      config.localPath,
      defaultDocument: config.defaultDocument,
      listDirectories: config.listDirectories,
    );

    // Wrap it to work with Diana's DianaHandler interface
    return (DianaRequest request) async {
      // Convert Diana DianaRequest to Shelf Request
      final shelfRequest = _convertToShelfRequest(request);

      // Call the shelf static handler
      final shelfResponse = await shelfHandler(shelfRequest);

      // Convert Shelf Response back to Diana DianaResponse
      return ShelfResponseAdapter.fromShelf(shelfResponse);
    };
  }

  /// Convert Diana DianaRequest to Shelf Request
  shelf.Request _convertToShelfRequest(DianaRequest request) {
    // If it's already a ShelfRequestAdapter, extract the underlying request
    if (request is ShelfRequestAdapter) {
      return request.shelfRequest;
    }

    // Otherwise, create a new shelf request
    return shelf.Request(
      request.method,
      request.uri,
      headers: request.headers,
      body: request.readAsStream(),
      context: Map<String, Object>.from(request.context),
    );
  }
}
