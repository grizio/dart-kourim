part of kourim.description;

Future<bool> _isExpired(IModelStorage modelStorage, Option<Duration> duration) {
  return modelStorage['_cacheForTable'].find(_tableName).then((Option<Map> isExpired) {
    if (isExpired.isDefined) {
      if (duration.isDefined) {
        var date = new DateTime.fromMillisecondsSinceEpoch(isExpired.value['start']);
        date = date.add(duration.value);
        return date.isAfter(new DateTime.now());
      } else {
        return false;
      }
    } else {
      return true;
    }
  });
}

class RemoteQueryCache {
  final String remote;
  final Duration duration;

  RemoteQueryCache(this.remote, this.duration);
}

abstract class Query {
  Future<dynamic> execute([Map<String, Object> parameters={}]);

  List<String> _requiredParameters = [];

  Query clone([Query clone]) {
    if (clone == null) {
      return null;
    } else {
      clone.requiredParameters [];
      clone.requiredParameters.addAll(requiredParameters);
      return clone;
    }
  }
}

abstract class RemoteQuery extends Query {
  final String remote;
  final String type;
  Option<RemoteQueryCache> cache = None;
  Option<GetQuery> then = None;

  RemoteQuery(this.remote, this.type) {
    _extractParametersFromRemote();
  }

  void _extractParametersFromRemote() {
    _requiredParameters.addAll(new RegExp('{([^}]+)}').allMatches(remote).map((_) => _.group(1)));
  }

  RemoteQuery withCache(String destination, Duration duration) {
    var clone = clone();
    clone.cache = Some(new TableCache(destination, duration));
  }

  RemoteQuery then(GetQuery query) {
    var clone = clone();
    clone.then = Some(query);
  }

  @override
  RemoteQuery clone([RemoteQuery clone]) {
    clone = super.clone(clone);
    if (clone == null) {
      return null;
    } else {
      clone.remote = remote;
      clone.type = type;
      clone.cache = cache;
      return clone;
    }
  }
}

abstract class ParameterRemoteQuery extends RemoteQuery {
  List<String> optionalParameters = [];

  ParameterRemoteQuery requiring(List<String> parameters) {
    var clone = clone();
    clone.requiredParameters.addAll(parameters);
    return clone;
  }

  ParameterRemoteQuery optional(List<String> parameters) {
    var clone = clone();
    clone.optionalParameters.addAll(parameters);
    return clone;
  }

  @override
  ParameterRemoteQuery clone([ParameterRemoteQuery clone]) {
    clone = super.clone(clone);
    if (clone == null) {
      return null;
    } else {
      clone.optionalParameters = [];
      clone.optionalParameters.addAll(optionalParameters);
      return clone;
    }
  }
}

class GetQuery extends RemoteQuery {
  final Option<String> keyName;

  GetQuery(String remote, [String keyName]): super(remote, 'get') {
    this.keyName = Some(keyName);
  }

  @override
  GetQuery clone([GetQuery clone]) {
    if (clone == null) {
      clone = new GetQuery(remote, keyName);
    }
    return super.clone(clone);
  }
}

class PostQuery extends ParameterRemoteQuery {
  PostQuery(String remote): super(remote, 'post');

  @override
  PostQuery clone([PostQuery clone]) {
    if (clone == null) {
      clone = new PostQuery(remote);
    }
    return super.clone(clone);
  }
}

class PutQuery extends ParameterRemoteQuery {
  PutQuery(String remote): super(remote, 'put');

  @override
  PutQuery clone([PutQuery clone]) {
    if (clone == null) {
      clone = new PutQuery(remote);
    }
    return super.clone(clone);
  }
}

class DeleteQuery extends RemoteQuery {
  DeleteQuery(String remote): super(remote, 'delete');

  @override
  DeleteQuery clone([DeleteQuery clone]) {
    if (clone == null) {
      clone = new DeleteQuery(remote);
    }
    return super.clone(clone);
  }
}

class LocalQuery extends Query {
  @override
  LocalQuery clone([LocalQuery clone]) {
    if (clone == null) {
      clone = new LocalQuery(remote);
    }
    return super.clone(clone);
  }
}

class FindAllQuery extends Query {
  final GetQuery _getQuery;
  final IModelStorage _modelStorage;
  final Option<Duration> _duration;
  final String _tableName;
  Future _loading;

  FindAllQuery(this._getQuery, this._modelStorage, this._duration, this._tableName);

  @override
  Future<dynamic> execute(Map<String, Object> parameters) {
    if (_loading == null) {
      _loading = _isExpired(_modelStorage, _duration).then((isExpired) {
        if (isExpired) {
          return _getQuery.execute().then((List<Map> result) {
            var resultByKey = {};
            for (var line in result) {
              resultByKey[line[_key.value]] = line;
            }
            return _modelStorage[_tableName].clean().then((_) {
              return _modelStorage[_tableName].putMany(resultByKey);
            });
            return result;
          });
        } else {
          return _modelStorage[_tableName].findAll();
        }
      });
    }
    return _loading.then((_) {
      _loading = null;
      return _;
    });
  }

  @override
  FindAllQuery clone([FindAllQuery clone]) {
    if (clone == null) {
      clone = new FindAllQuery(_getQuery, _modelStorage, _duration, _tableName);
    }
    return super.clone(clone);
  }
}

class FindQuery extends Query {
  final GetQuery _getQuery;
  final IModelStorage _modelStorage;
  final Option<Duration> _duration;
  final String _tableName;
  Map<Object, Future> _loading = {};

  FindQuery(this._getQuery, this._modelStorage, this._duration, this._tableName);

  @override
  Future<dynamic> execute(Map<String, Object> parameters) {
    if (_getQuery._requiredParameters.isEmpty) {
      throw 'The query from PartialCachedTable.loadOne must contains one parameter as a key of the queried object.';
    } else {
      var keyName = _getQuery._requiredParameters[0];
      var key = parameters[keyName];
      if (_loading.containsKey(key)) {
        _loading[key] = _isExpired(_modelStorage, _duration).then((isExpired) {
          if (isExpired) {
            return loadOne.execute({keyName.value: key}).then((result) {
              return _modelStorage[_tableName].putOne(key, result).then((_) {
                return result;
              });
            });
          } else {
            return _modelStorage[_tableName].find(key);
          }
        });
      }
      return _loading[key].then((_) {
        _loading.remove(key);
        return _;
      });
    }
  }

  @override
  FindQuery clone([FindQuery clone]) {
    if (clone == null) {
      clone = new FindQuery(_getQuery, _modelStorage, _duration, _tableName);
    }
    return super.clone(clone);
  }
}