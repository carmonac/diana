/// This annotation is used to mark a method parameter as a query value coming in the url.
/// Example usage:
/// ```dart
///  void handleRequest(@Query('id') String id) {
///    ...Handle the request using the query parameter 'id'
/// }
/// ```
/// The [key] parameter specifies the name of the query parameter to extract.
class Query {
  final String key;

  const Query(this.key);
}
