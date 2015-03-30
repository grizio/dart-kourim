part of kourim.description;

/*
void _extractParametersFromRemote() {
    _requiredParameters.addAll(new RegExp('{([^}]+)}').allMatches(remote).map((_) => _.group(1)));
  }
*/

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
  final Table table;
  final String remote;
  final Option<ITableStorage> tableStorage;
  final Option<Duration> cacheDuration;
  final GetQuery then;
  final List<Field> requiredParameters;

  const GetQuery(this.table, this.remote, this.tableStorage, this.cacheDuration, this.then, this.requiredParameters);

  GetQuery withCache(ITableStorage tableStorage, [Duration duration=null]) {
    return new GetQuery(table, remote, Some(tableStorage), Some(cacheDuration), then, requiredParameters);
  }

  GetQuery requiring(dynamic fields) {
    var newRequiredParameters = [];
    newRequiredParameters.addAll(requiredParameters);
    if (fields is List) {
      newRequiredParameters.addAll(fields);
    } else {
      newRequiredParameters.add(fields);
    }
    return new GetQuery(table, remote, tableStorage, cacheDuration, then, newRequiredParameters);
  }
}

class PostQuery implements Query {
  final Table table;
  final String remote;
  final List<Field> requiredParameters;
  final List<Field> optionalParameters;

  const PostQuery(this.table, this.remote, this.requiredParameters, this.optionalParameters);

  PostQuery requiring(dynamic fields) {
    var newRequiredParameters = <Field>[];
    newRequiredParameters.addAll(requiredParameters);
    if (fields is List) {
      newRequiredParameters.addAll(fields);
    } else {
      newRequiredParameters.add(fields);
    }
    return new PostQuery(table, remote, newRequiredParameters, optionalParameters);
  }

  PostQuery optional(dynamic fields) {
    var newOptionalParameters = <Field>[];
    newOptionalParameters.addAll(optionalParameters);
    if (fields is List) {
      newOptionalParameters.addAll(fields);
    } else {
      newOptionalParameters.add(fields);
    }
    return new PostQuery(table, remote, requiredParameters, newOptionalParameters);
  }
}

class PutQuery implements Query {
  final Table table;
  final String remote;
  final List<Field> requiredParameters;
  final List<Field> optionalParameters;

  const PutQuery(this.table, this.remote, this.requiredParameters, this.optionalParameters);

  PutQuery requiring(dynamic fields) {
    var newRequiredParameters = <Field>[];
    newRequiredParameters.addAll(requiredParameters);
    if (fields is List) {
      newRequiredParameters.addAll(fields);
    } else {
      newRequiredParameters.add(fields);
    }
    return new PutQuery(table, remote, newRequiredParameters, optionalParameters);
  }

  PutQuery optional(dynamic fields) {
    var newOptionalParameters = <Field>[];
    newOptionalParameters.addAll(optionalParameters);
    if (fields is List) {
      newOptionalParameters.addAll(fields);
    } else {
      newOptionalParameters.add(fields);
    }
    return new PutQuery(table, remote, requiredParameters, newOptionalParameters);
  }
}

class DeleteQuery implements Query {
  final Table table;
  final String remote;
  final List<Field> requiredParameters;

  const DeleteQuery(this.table, this.remote, this.requiredParameters);

  DeleteQuery requiring(dynamic fields) {
    var newRequiredParameters = <Field>[];
    newRequiredParameters.addAll(requiredParameters);
    if (fields is List) {
      newRequiredParameters.addAll(fields);
    } else {
      newRequiredParameters.add(fields);
    }
    return new DeleteQuery(table, remote, newRequiredParameters);
  }
}

class LocalQuery implements Query {
  final FullCachedTable table;
  final String remote;
  final ITableStorage tableStorage;
  final List<Constraint> constraints;

  const LocalQuery(this.table, this.remote, this.tableStorage, this.constraints);

  LocalQuery verifying(Constraint constraint) {
    var newConstraints = [];
    newConstraints.addAll(constraints);
    return new LocalQuery(table, remote, tableStorage, newConstraints);
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
  final Table table;
  final GetQuery getQuery;
  final ITableStorage tableStorage;
  final Duration cacheDuration;
  Future _loading;

  // cannot be const because of _loading.
  FindAllQuery(this.table, this.getQuery, this.tableStorage, this.cacheDuration);

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
    return modelStorage['_cacheForTable'].find(tableStorage.name).then((Option<Map> isExpired) {
      if (isExpired.isDefined) {
        var date = new DateTime.fromMillisecondsSinceEpoch(isExpired.value['start']);
        date = date.add(cacheDuration);
        return date.isAfter(new DateTime.now());
      } else {
        return true;
      }
    });
  }
}

class FindQuery implements Query, PreparedQuery {
  final Table table;
  final GetQuery getQuery;
  final ITableStorage tableStorage;
  final Duration cacheDuration;
  Map<Object, Future> _loading = {};

  // cannot be const because of _loading.
  FindQuery(this.table, this.getQuery, this.tableStorage, this.cacheDuration);

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
    return modelStorage['_cacheForTable'].find(tableStorage.name + key).then((Option<Map> isExpired) {
      if (isExpired.isDefined) {
        var date = new DateTime.fromMillisecondsSinceEpoch(isExpired.value['start']);
        date = date.add(cacheDuration);
        return date.isAfter(new DateTime.now());
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