part of kourim.description;

abstract class Query {
  /// Executes the current Query with given [parameters].
  /// If the query is a read query (cf. [GetQuery], [FindAllQuery] and [FindQuery]),
  /// then the result will be a list of lines matching the query.
  /// Otherwise, it will be null (the [Future] is used to determine the end of the query).
  Future<dynamic> execute([Map<String, Object> parameters]);
}

abstract class PreparedQuery {
  /// Prepares the query by caching the result into given [tableStorage].
  /// This methods is mainly used by the system to get data for [FullCachedTable] or [PartialCachedTable].
  ///
  /// It can also be used by the developer is he want to copy the result into another table.
  /// Then, when he will change data, it could use the copied table and not change original data.
  Future prepare(ITableStorage tableStorage, [Map<String, Object> parameters]);
}

abstract class Constraint {
  String get key;
  bool get isRequired;
  bool validate(Map<String, Object> data, Object value);
}

class GetQuery implements Query, PreparedQuery {
  final Injector injector;
  final Table table;
  final String remote;
  final Option<IModelStorage> modelStorage;
  final Option<Duration> cacheDuration;
  final Option<GetQuery> nextQuery;
  final List<Field> requiredParameters;
  Map<String, Future> _loading = {}; // Avoids calling the same url multiple time on the same moment.

  GetQuery(this.injector, this.table, this.remote, this.modelStorage, this.cacheDuration, this.nextQuery, this.requiredParameters);

  GetQuery withCache(Type destination, [Duration duration=null]) {
    var modelStorage = injector.get(IModelStorage, destination);
    return new GetQuery(injector, table, remote, Some(modelStorage), Some(duration), nextQuery, requiredParameters);
  }

  GetQuery then(GetQuery getQuery) {
    return new GetQuery(injector, table, remote, modelStorage, cacheDuration, Some(getQuery), requiredParameters);
  }

  @override
  Future<dynamic> execute([Map<String, Object> parameters]) {
    parameters = mapUtilities.notNull(parameters);
    if (modelStorage.isDefined) {
      var tableStorage = modelStorage.value[this.table._tableName + JSON.encode(parameters)];
      return prepare(tableStorage).then((_){
        return tableStorage.findAll();
      });
    } else {
      var modelStorage = injector.get(IModelStorage, session) as IModelStorage;
      var tableStorage = modelStorage[this.table._tableName + JSON.encode(parameters) + new Random().nextInt(10000).toString()];
      return prepare(tableStorage).then((_){
        var result = tableStorage.findAll();
        tableStorage.clean();
        return result;
      });
    }
  }

  @override
  Future prepare(ITableStorage tableStorage, [Map<String, Object> parameters]) {
    parameters = mapUtilities.notNull(parameters);
    var key = table._tableName + JSON.encode(parameters);
    if (_loading[key] == null) {
      _loading[key] = _isExpired(parameters).then((isExpired){
        if (isExpired) {
          return _pull(tableStorage, parameters);
        } else {
          return new Future.value();
        }
      });
    }
    return _loading[key].then((_) {
      _loading[key] = null;
    });
  }

  Future _pull(ITableStorage tableStorage, Map<String, Object> parameters) {
    var url = remote;
    for (var requiredParameter in requiredParameters) {
      if (!parameters.containsKey(requiredParameter.name)) {
        throw 'A required parameter for the query was not found (local query from table ${table._tableName}})';
      } else {
        url = url.replaceAll('{${requiredParameter.name}}', parameters[requiredParameter.name]);
      }
    }

    var requestCreation = injector.get(IRequestCreation);
    var request = requestCreation() as IRequest;
    request.uri = url;
    request.method = 'GET';
    request.parseResult = true;
    return request.send().then((_){
      //TODO
    });
  }

  Future<bool> _isExpired(Map<String, Object> parameters) {
    if (modelStorage.isDefined) {
      return modelStorage.value['_cacheForQueries'].find(table._tableName + '.' + remote + JSON.encode(parameters)).then((Option<Map> cacheInfo) {
        if (cacheInfo.isDefined) {
          if (cacheDuration.isDefined) {
            var date = new DateTime.fromMillisecondsSinceEpoch(cacheInfo.value['start']);
            date = date.add(cacheDuration.value);
            return date.isAfter(new DateTime.now());
          } else {
            return false;
          }
        } else {
          return true;
        }
      });
    } else {
      return new Future.value(true);
    }
  }
}

class PostQuery implements Query {
  final Injector injector;
  final Table table;
  final String remote;
  final List<Field> requiredParameters;
  final List<Field> optionalParameters;

  PostQuery(this.injector, this.table, this.remote, this.requiredParameters, this.optionalParameters);

  PostQuery requiring(dynamic fields) {
    var newRequiredParameters = <Field>[];
    newRequiredParameters.addAll(requiredParameters);
    if (fields is List) {
      newRequiredParameters.addAll(fields);
    } else {
      newRequiredParameters.add(fields);
    }
    return new PostQuery(injector, table, remote, newRequiredParameters, optionalParameters);
  }

  PostQuery optional(dynamic fields) {
    var newOptionalParameters = <Field>[];
    newOptionalParameters.addAll(optionalParameters);
    if (fields is List) {
      newOptionalParameters.addAll(fields);
    } else {
      newOptionalParameters.add(fields);
    }
    return new PostQuery(injector, table, remote, requiredParameters, newOptionalParameters);
  }

  @override
  Future<dynamic> execute([Map<String, Object> parameters]) {
    var url = remote;
    var params = {};
    for (var requiredParameter in requiredParameters) {
      var name = requiredParameter.name;
      if (!parameters.containsKey(name)) {
        throw 'A required parameter for the query was not found (local query from table ${table._tableName}})';
      } else {
        if (url.indexOf('{${name}}') != -1) {
          url = url.replaceAll('{${name}}', parameters[name]);
        } else {
          params[name] = parameters[name];
        }
      }
    }
    for (var optionalParameter in optionalParameters) {
      var name = optionalParameter.name;
      if (parameters.containsKey(name)) {
        params[name] = parameters[name];
      }
    }

    var requestCreation = injector.get(IRequestCreation);
    var request = requestCreation() as IRequest;
    request.uri = url;
    request.method = 'POST';
    request.parameters = params;
    request.parseResult = false;
    return request.send();
  }
}

class PutQuery implements Query {
  final Injector injector;
  final Table table;
  final String remote;
  final List<Field> requiredParameters;
  final List<Field> optionalParameters;

  PutQuery(this.injector, this.table, this.remote, this.requiredParameters, this.optionalParameters);

  PutQuery requiring(dynamic fields) {
    var newRequiredParameters = <Field>[];
    newRequiredParameters.addAll(requiredParameters);
    if (fields is List) {
      newRequiredParameters.addAll(fields);
    } else {
      newRequiredParameters.add(fields);
    }
    return new PutQuery(injector, table, remote, newRequiredParameters, optionalParameters);
  }

  PutQuery optional(dynamic fields) {
    var newOptionalParameters = <Field>[];
    newOptionalParameters.addAll(optionalParameters);
    if (fields is List) {
      newOptionalParameters.addAll(fields);
    } else {
      newOptionalParameters.add(fields);
    }
    return new PutQuery(injector, table, remote, requiredParameters, newOptionalParameters);
  }

  @override
  Future<dynamic> execute([Map<String, Object> parameters]) {
    var url = remote;
    var params = {};
    for (var requiredParameter in requiredParameters) {
      var name = requiredParameter.name;
      if (!parameters.containsKey(name)) {
        throw 'A required parameter for the query was not found (local query from table ${table._tableName}})';
      } else {
        if (url.indexOf('{${name}}') != -1) {
          url = url.replaceAll('{${name}}', parameters[name]);
        } else {
          params[name] = parameters[name];
        }
      }
    }
    for (var optionalParameter in optionalParameters) {
      var name = optionalParameter.name;
      if (parameters.containsKey(name)) {
        params[name] = parameters[name];
      }
    }

    var requestCreation = injector.get(IRequestCreation);
    var request = requestCreation() as IRequest;
    request.uri = url;
    request.method = 'PUT';
    request.parameters = params;
    request.parseResult = false;
    return request.send();
  }
}

class DeleteQuery implements Query {
  final Injector injector;
  final Table table;
  final String remote;
  final List<Field> requiredParameters;

  DeleteQuery(this.injector, this.table, this.remote, this.requiredParameters);

  @override
  Future<dynamic> execute([Map<String, Object> parameters]) {
    var url = remote;
    for (var requiredParameter in requiredParameters) {
      if (!parameters.containsKey(requiredParameter.name)) {
        throw 'A required parameter for the query was not found (local query from table ${table._tableName}})';
      } else {
        url = url.replaceAll('{${requiredParameter.name}}', parameters[requiredParameter.name]);
      }
    }

    var requestCreation = injector.get(IRequestCreation);
    var request = requestCreation() as IRequest;
    request.uri = url;
    request.method = 'DELETE';
    request.parseResult = false;
    return request.send();
  }
}

class LocalQuery implements Query {
  final Injector injector;
  final FullCachedTable table;
  final String remote;
  final ITableStorage tableStorage;
  final List<Constraint> constraints;

  LocalQuery(this.injector, this.table, this.remote, this.tableStorage, this.constraints);

  LocalQuery verifying(Constraint constraint) {
    var newConstraints = [];
    newConstraints.addAll(constraints);
    return new LocalQuery(injector, table, remote, tableStorage, newConstraints);
  }

  @override
  Future<dynamic> execute([Map<String, Object> parameters]) {
    return table.findAll.prepare(tableStorage).then((_){
      for (var constraint in constraints) {
        if (constraint.isRequired && !parameters.containsKey(constraint.key)) {
          throw 'A required parameter for the query was not found (local query from table ${table._tableName}})';
        }
      }
      tableStorage.findManyWhen((data){
        for (var constraint in constraints) {
          if (parameters.containsKey(constraint.key)) {
            if (!constraint.validate(data, parameters[key])) {
              return false;
            }
          }
        }
        return true;
      });
    });
  }
}

class FindAllQuery implements Query, PreparedQuery {
  final Injector injector;
  final Table table;
  final GetQuery getQuery;
  final ITableStorage tableStorage;
  final Option<Duration> cacheDuration;
  Future _loading; // Avoids calling the same url multiple time on the same moment.

  // cannot be const because of _loading.
  FindAllQuery(this.injector, this.table, this.getQuery, this.tableStorage, this.cacheDuration);

  @override
  Future<dynamic> execute([Map<String, Object> parameters, ITableStorage ts]) {
    return prepare(tableStorage).then((_){
      return tableStorage.findAll();
    });
  }

  @override
  Future prepare(ITableStorage tableStorage, [Map<String, Object> parameters]) {
    if (_loading == null) {
      _loading = _isExpired().then((isExpired) {
        if (isExpired) {
          return getQuery.prepare(tableStorage);
        } else {
          return new Future.value();
        }
      });
    }
    return _loading.then((_) {
      _loading = null;
    });
  }

  Future<bool> _isExpired() {
    IModelStorage modelStorage = tableStorage.modelStorage;
    return modelStorage['_cacheForTable'].find(tableStorage.name).then((Option<Map> cacheInfo) {
      if (cacheInfo.isDefined) {
        if (cacheDuration.isDefined) {
          var date = new DateTime.fromMillisecondsSinceEpoch(cacheInfo.value['start']);
          date = date.add(cacheDuration.value);
          return date.isAfter(new DateTime.now());
        } else {
          return false;
        }
      } else {
        return true;
      }
    });
  }
}

class FindQuery implements Query, PreparedQuery {
  final Injector injector;
  final Table table;
  final GetQuery getQuery;
  final ITableStorage tableStorage;
  final Option<Duration> cacheDuration;
  Map<Object, Future> _loading = {}; // Avoids calling the same url multiple time on the same moment.

  // cannot be const because of _loading.
  FindQuery(this.injector, this.table, this.getQuery, this.tableStorage, this.cacheDuration);

  @override
  Future<dynamic> execute([Map<String, Object> parameters]) {
    parameters = parameters != null ? parameters : {};
    return prepare(tableStorage, parameters).then((_){
      return tableStorage.find(parameters[_keyName]);
    });
  }

  @override
  Future prepare(ITableStorage tableStorage, [Map<String, Object> parameters]) {
    Object key = parameters[_keyName];
    if (_loading[key] == null) {
      _loading[key] = _isExpired(key).then((isExpired) {
        if (isExpired) {
          return getQuery.prepare(tableStorage);
        } else {
          return new Future.value();
        }
      });
    }
    return _loading[key].then((_) {
      _loading[key] = null;
    });
  }

  Future<bool> _isExpired(Object key) {
    IModelStorage modelStorage = tableStorage.modelStorage;
    return modelStorage['_cacheForTable'].find(tableStorage.name + key).then((Option<Map> cacheInfo) {
      if (cacheInfo.isDefined) {
        if (cacheDuration.isDefined) {
          var date = new DateTime.fromMillisecondsSinceEpoch(cacheInfo.value['start']);
          date = date.add(cacheDuration.value);
          return date.isAfter(new DateTime.now());
        } else {
          return false;
        }
      } else {
        return true;
      }
    });
  }

  String get _keyName {
    if (getQuery.requiredParameters.length != 1) {
      throw 'The query used by a partial table cache must contains one parameter.';
    } else {
      return getQuery.requiredParameters[0].name;
    }
  }
}