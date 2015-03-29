part of kourim.query.interface;

/// Defines classes which can make HTTP request with some configurations and return its result.
abstract class IRequest {
  /// URI of the request.
  /// This URI cannot be a pattern url because it will be used as is.
  String uri;

  /// Method of the request, should be a valid HTTP method.
  String method;

  /// Parameters to send to the request.
  /// These parameters is only the body parameter.
  Map<String, Object> parameters;

  /// If true, the result will be parsed into JSON before returning to caller.
  /// Otherwise, the request will not return a result.
  bool parseResult;

  /// Sends the HTTP request and returns its result.
  Future<dynamic> send();
}