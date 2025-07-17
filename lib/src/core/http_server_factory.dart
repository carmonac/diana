import 'package:diana/src/adapter/shelf/shelf_adapter.dart';
import 'package:diana/src/core/http_lib.dart';
import 'package:diana/src/http/interfaces.dart';

class DianaServerFactory {
  static DianaServer create(HttpLib lib) {
    switch (lib) {
      case HttpLib.shelf:
        return ShelfHttpAdapter();
      // case HttpLib.relic:
      //   return RelicHttpAdapter(); // Future implementation
      default:
        return ShelfHttpAdapter();
    }
  }
}
