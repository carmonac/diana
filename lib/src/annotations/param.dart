/// This annotation is used to mark a method parameter as a query value coming in the url.
/// Example usage:
/// ```dart
///  void handleRequest(@Param('id') String id) {
///    ...Handle the request using the parameter 'id'
/// }
/// ```
/// The [key] parameter specifies the name of the query parameter to extract.
class Param {
  final String key;

  const Param(this.key);
}
