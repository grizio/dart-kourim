part of kourim.query.lib;

/// This class is the default implementation of [IRequest] and is used in production mode.
class Request extends IRequest {
  Option<String> _uri = None;
  Option<String> _method = None;
  Option<Map<String, Object>> _parameters = None;

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
    var completer = new Completer<dynamic>();

    var xhr = new HttpRequest();
    xhr.open(method, uri, async: true);

    xhr.onLoad.listen((e) {
      if ((xhr.status >= 200 && xhr.status < 300) ||
          xhr.status == 0 || xhr.status == 304) {
        completer.complete(JSON.decode(xhr.responseText));
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