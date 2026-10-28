/// Thrown for anything that stops a request from producing a usable body:
/// no connectivity, a timeout, a non-2xx status, or a malformed payload.
class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => 'ApiException($statusCode): $message';
}
