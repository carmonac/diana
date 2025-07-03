abstract class ShelfMiddlewareAnnotation {
  final Type shelfMiddleware;
  final Map<String, dynamic> options;
  const ShelfMiddlewareAnnotation(
    this.shelfMiddleware, {
    this.options = const {},
  });
}

class ShelfMiddleware extends ShelfMiddlewareAnnotation {
  const ShelfMiddleware(super.shelfMiddleware, {super.options = const {}});
}

class GlobalShelfMiddleware extends ShelfMiddlewareAnnotation {
  const GlobalShelfMiddleware(
    super.shelfMiddleware, {
    super.options = const {},
  });
}
