part of kourim.query;

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

  /// Sends the HTTP request and returns its result.
  Future<dynamic> send();
}

/// This class is the default implementation of [IRequest] and is used in production mode.
class Request extends IRequest {
  Option<String> _uri;
  Option<String> _method;
  Option<Map<String, Object>> _parameters;

  @override
  set uri(String uri) => _uri = Some(uri);

  @override
  String get uri => _uri.get();

  @override
  set method(String method) => _method = Some(method);

  @override
  String get method => _method.get();

  @override
  set parameters(Map<String, Object> parameters) => _parameters = Some(parameters);

  @override
  Map<String, Object> get parameters => _parameters.get();

  @override
  Future<dynamic> send() {
    if (_uri == None || _method == None) {
      throw 'You must provide a valid URI and a valid method before sending a HTTP Request.';
    }
    var completer = new Completer<HttpRequest>();

    var xhr = new HttpRequest();
    xhr.open(method, uri, async: true);

    xhr.onLoad.listen((e) {
      if ((xhr.status >= 200 && xhr.status < 300) ||
          xhr.status == 0 || xhr.status == 304) {
        completer.complete(xhr);
      } else {
        completer.completeError(e);
      }
    });

    if (_parameters.isDefined) {
      xhr.send(parameters);
    } else {
      xhr.send();
    }

    return completer.future;
  }
}