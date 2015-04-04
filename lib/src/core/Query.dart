part of kourim.core;

/// Describes a classic query
abstract class Query {
  /// Executes the current Query with given [parameters].
  /// If the query is a read query (cf. [GetQuery], [FindAllQuery] and [FindQuery]),
  /// then the result will be a list of lines matching the query.
  /// Otherwise, it will be null (the [Future] is used to determine the end of the query).
  Future<dynamic> execute([Map<String, Object> parameters]);
}

/// Describes a query which can be prepared.
abstract class PreparedQuery {
  /// Prepares the query by caching the result into given [tableStorage].
  /// This methods is mainly used by the system to get data for [FullCachedTable] or [PartialCachedTable].
  ///
  /// It can also be used by the developer is he want to copy the result into another table.
  /// Then, when he will change data, it could use the copied table and not change original data.
  Future<bool> prepare(ITableStorage tableStorage, [Map<String, Object> parameters]);
}

/// Descriptor for a remote `GET` query.
class GetQuery implements Query, PreparedQuery {
  final Injector injector;
  final Table table;
  final String remote;
  final Option<IModelStorage> modelStorage;
  final Option<Duration> cacheDuration;
  final Option<GetQuery> nextQuery;
  final List<Field> requiredParameters;
  Map<String, Future> _loading = {}; // Avoids calling the same url multiple times on the same moment.

  GetQuery(this.injector, this.table, this.remote, this.modelStorage, this.cacheDuration, this.nextQuery, this.requiredParameters);

  /// Adds a cache management to save the result of given query.
  /// If the cache is already set, it will be overridden.
  GetQuery withCache(Type destination, [Duration duration=null]) {
    var modelStorage = injector.get(IModelStorage, destination);
    return new GetQuery(injector, table, remote, Some(modelStorage), Some(duration), nextQuery, requiredParameters);
  }

  /// Indicates that the given query must call another query after getting its result.
  GetQuery then(GetQuery getQuery) {
    return new GetQuery(injector, table, remote, modelStorage, cacheDuration, Some(getQuery), requiredParameters);
  }

  @override
  Future<dynamic> execute([Map<String, Object> parameters]) {
    parameters = mapUtilities.notNull(parameters);
    var temporaryModelStorage = injector.get(IModelStorage, Session) as IModelStorage;
    var temporaryTableStorage = temporaryModelStorage[this.table._tableName + JSON.encode(parameters) + new Random().nextInt(10000).toString()];
    return prepare(temporaryTableStorage).then((pulled){
      return temporaryTableStorage.findAll().then((result) {
        if (pulled) {
          if (modelStorage.isDefined) {
            var storage = modelStorage.value;
            if (storage is IDatabase) {
              // It is the indexedDB which cannot have tables creating dynamically.
              return storage['__queries']
                .putOne(this.table._tableName + JSON.encode(parameters), {'result': result})
                .then((_) => result);
            } else {
              // It is localStorage or sessionStorage, we cannot get all in only one table.
              var map = {};
              for (var row in result) {
                map[row[table._key.name]] = row;
              }
              return storage['__' + this.table._tableName + JSON.encode(parameters)]
                .putMany(map)
                .then((_) => result);
            }
          }
        } else {
          // Always a model storage.
          var storage = modelStorage.value;
          if (storage is IDatabase) {
            return storage['__queries']
              .find(this.table._tableName + JSON.encode(parameters))
              .then((_) => _.value['result']);
          } else {
            return storage['__' + this.table._tableName + JSON.encode(parameters)]
              .findAll();
          }
        }
      });
    }).then((result){
      temporaryTableStorage.clean();
      return result;
    });
  }

  @override
  Future<bool> prepare(ITableStorage tableStorage, [Map<String, Object> parameters]) {
    parameters = mapUtilities.notNull(parameters);
    var key = table._tableName + '.' + tableStorage.name + JSON.encode(parameters);
    if (_loading[key] == null) {
      _loading[key] = _isExpired(parameters).then((isExpired){
        if (isExpired) {
          return _pull(tableStorage, parameters).then((_) => true);
        } else {
          return new Future.value(false);
        }
      });
    }
    return _loading[key].then((_) {
      _loading[key] = null;
      return _;
    });
  }

  /// Pulls data from remote host.
  Future _pull(ITableStorage tableStorage, Map<String, Object> parameters) {
    var url = remote;
    for (var requiredParameter in requiredParameters) {
      if (!parameters.containsKey(requiredParameter.name)) {
        throw 'A required parameter for the query was not found (local query from table ${table._tableName}})';
      } else {
        url = url.replaceAll('{${requiredParameter.name}}', parameters[requiredParameter.name].toString());
      }
    }

    var requestCreation = injector.get(IRequestCreation);
    var request = requestCreation() as IRequest;
    var host = (injector.get(ApplicationRemoteHost) as ApplicationRemoteHost).host;
    host += host.endsWith('/') ? '' : '/';
    host += url.startsWith('/') ? url.substring(1) : url;
    request.uri = host;
    request.method = 'GET';
    request.parseResult = true;
    return request.send().then((values) {
      if (nextQuery.isDefined) {
        return _processNextQuery(tableStorage, values);
      } else {
        return _save(tableStorage, values);
      }
    });
  }

  /// Executes the next query.
  Future _processNextQuery(ITableStorage tableStorage, dynamic values) {
    if (values is List) {
      return Future.wait((values as List).map((_) => _processNextQuery(tableStorage, _)));
    } else if (values is Map) {
      return nextQuery.value.prepare(tableStorage, values);
    } else {
      return nextQuery.value.prepare(tableStorage, {nextQuery.value.requiredParameters.first.name: values});
    }
  }

  /// Save the result of given query into current table storage.
  Future _save(ITableStorage tableStorage, dynamic values) {
    if (values is List) {
      var mapValues = <Object, Map<String, Object>>{};
      (values as List).forEach((line){
        var key = line[table._key.name];
        mapValues[key] = line;
      });
      return tableStorage.putMany(mapValues);
    } else {
      var key = values[table._key.name];
      return tableStorage.putOne(key, values);
    }
  }

  /// Checks if the cache (if any) for this query and given [parameters] is expired.
  Future<bool> _isExpired(Map<String, Object> parameters) {
    if (modelStorage.isDefined) {
      return modelStorage.value['__cacheForQueries'].find(table._tableName + '.' + remote + JSON.encode(parameters)).then((Option<Map> cacheInfo) {
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

/// Descriptor for a remote `POST` query.
class PostQuery implements Query {
  final Injector injector;
  final Table table;
  final String remote;
  final List<Field> requiredParameters;
  final List<Field> optionalParameters;

  PostQuery(this.injector, this.table, this.remote, this.requiredParameters, this.optionalParameters);

  /// Indicates that the given query must require the given fields.
  /// Warning: The system will check if the value was provided, not if it is not null.
  /// Provide a single [Field] element or a [List<Field>] (not as a rest parameters due to langage limitations).
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

  /// Indicates that the given query can add the given fields, but are not required.
  /// Warning: The query checks if the value was provided, not if it is not null.
  /// Provide a single [Field] element or a [List<Field>] (not as a rest parameters due to langage limitations).
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

/// Descriptor for a remote `PUT` query.
class PutQuery implements Query {
  final Injector injector;
  final Table table;
  final String remote;
  final List<Field> requiredParameters;
  final List<Field> optionalParameters;

  PutQuery(this.injector, this.table, this.remote, this.requiredParameters, this.optionalParameters);

  /// Indicates that the given query must require the given fields.
  /// Warning: The system will check if the value was provided, not if it is not null.
  /// Provide a single [Field] element or a [List<Field>] (not as a rest parameters due to langage limitations).
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

  /// Indicates that the given query can add the given fields, but are not required.
  /// Warning: The query checks if the value was provided, not if it is not null.
  /// Provide a single [Field] element or a [List<Field>] (not as a rest parameters due to langage limitations).
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

/// Descriptor for a remote `DELETE` query.
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

/// Descriptor for a local query (when into a [FullCachedTable]).
class LocalQuery implements Query {
  final Injector injector;
  final FullCachedTable table;
  final ITableStorage tableStorage;
  final List<Constraint> constraints;

  LocalQuery(this.injector, this.table, this.tableStorage, this.constraints);

  /// Indicates that the system must return only rows verifying given [constraint].
  /// See [Constraint] for more explanations.
  LocalQuery verifying(Constraint constraint) {
    var newConstraints = [];
    newConstraints.add(constraint);
    return new LocalQuery(injector, table, tableStorage, newConstraints);
  }

  @override
  Future<dynamic> execute([Map<String, Object> parameters]) {
    return table.findAll.prepare(tableStorage).then((_){
      for (var constraint in constraints) {
        if (constraint.isRequired && !parameters.containsKey(constraint.key)) {
          throw 'A required parameter for the query was not found (local query from table ${table._tableName}})';
        }
      }
      return tableStorage.findManyWhen((data){
        for (var constraint in constraints) {
          if (parameters.containsKey(constraint.key)) {
            if (!constraint.validate(data, parameters[constraint.key])) {
              return false;
            }
          }
        }
        return true;
      });
    });
  }
}

/// Descriptor for the special query [FullCachedTable.findAll].
class FindAllQuery implements Query, PreparedQuery {
  final Injector injector;
  final Table table;
  final GetQuery getQuery;
  final ITableStorage tableStorage;
  final Option<Duration> cacheDuration;
  Future _loading; // Avoids calling the same url multiple times on the same moment.

  FindAllQuery(this.injector, this.table, this.getQuery, this.tableStorage, this.cacheDuration);

  @override
  Future<dynamic> execute([Map<String, Object> parameters, ITableStorage ts]) {
    return prepare(tableStorage).then((_){
      return tableStorage.findAll();
    });
  }

  @override
  Future<bool> prepare(ITableStorage tableStorage, [Map<String, Object> parameters]) {
    if (_loading == null) {
      _loading = _isExpired().then((isExpired) {
        if (isExpired) {
          return tableStorage.clean().then((_){
            return getQuery.prepare(tableStorage).then((_) => true);
          });
        } else {
          return new Future.value(false);
        }
      });
    }
    return _loading.then((_) {
      _loading = null;
      return _;
    });
  }

  /// Checks if the cache (if any) for this query table is expired.
  Future<bool> _isExpired() {
    IModelStorage modelStorage = tableStorage.modelStorage;
    return modelStorage['__cacheForTable'].find(tableStorage.name).then((Option<Map> cacheInfo) {
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

/// Descriptor for the special query [PartialCachedTable.find].
class FindQuery implements Query, PreparedQuery {
  final Injector injector;
  final Table table;
  final GetQuery getQuery;
  final ITableStorage tableStorage;
  final Option<Duration> cacheDuration;
  Map<Object, Future> _loading = {}; // Avoids calling the same url multiple times on the same moment.

  FindQuery(this.injector, this.table, this.getQuery, this.tableStorage, this.cacheDuration);

  @override
  Future<dynamic> execute([Map<String, Object> parameters]) {
    parameters = parameters != null ? parameters : {};
    return prepare(tableStorage, parameters).then((_){
      return tableStorage.find(parameters[_keyName]);
    });
  }

  @override
  Future<bool> prepare(ITableStorage tableStorage, [Map<String, Object> parameters]) {
    Object key = parameters[_keyName];
    if (_loading[key] == null) {
      _loading[key] = _isExpired(key).then((isExpired) {
        if (isExpired) {
          return tableStorage.clean().then((_){
            return getQuery.prepare(tableStorage).then((_) => true);
          });
        } else {
          return new Future.value(false);
        }
      });
    }
    return _loading[key].then((_) {
      _loading[key] = null;
      return _;
    });
  }

  /// Checks if the cache (if any) for this query table and givne key is expired.
  Future<bool> _isExpired(Object key) {
    IModelStorage modelStorage = tableStorage.modelStorage;
    return modelStorage['__cacheForTable'].find(tableStorage.name + '.' + key).then((Option<Map> cacheInfo) {
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

  /// Returns the key name of the query to call it with key parameter.
  String get _keyName {
    if (getQuery.requiredParameters.length != 1) {
      throw 'The query used by a partial table cache must contains one parameter.';
    } else {
      return getQuery.requiredParameters[0].name;
    }
  }
}