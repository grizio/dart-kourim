part of kourim.query.lib;

/// This class is the default implementation of IQueryBuilder and is used in production mode.
class QueryBuilder extends IQueryBuilder {
  // TODO: The system uses only JSON. See how we can use other formats.

  static final Logger log = new Logger('kourim.query.QueryBuilder');

  Query query;
  IEntityManager em;
  bool isThen;

  Map<String, Object> parameters = {};
  Option<Constraint> _constraint = None;

  QueryBuilder(this.query, this.em, [bool this.isThen=false]);

  @override
  void addParameter(String name, Object value) {
    parameters[name] = value;
  }

  @override
  void addParameters(Map<String, Object> values) {
    values.keys.forEach((key) => addParameter(key, values[key]));
  }

  @override
  addInputEntity(Object object) {
    addParameters(factory.mapper.toJsonOne(query.model, object, query.fields));
  }

  @override
  Option<Constraint> get constraint {
    return _constraint;
  }

  @override
  void setConstraint(Constraint constraint) {
    _constraint = Some(constraint);
  }

  @override
  Future<dynamic> execute() {
    log.info('execute(${query.fullName}, ${JSON.encode(parameters)}) start');
    return _execute().then((_) {
      log.info('execute(${query.fullName}, ${JSON.encode(parameters)}) end');
      return _;
    });
  }

  @override
  Future clean() {
    log.fine('Cleaning the query ${query.fullName}');
    var queryCache = new Cache.query(this, query, parameters);
    if (query.storage.isDefined) {
      if (query.storage == Some(constants.indexedDB)) {
        var tableStorage = factory.internalDatabase[query.fullName];
        if (query.strategy == constants.row) {
          return tableStorage.remove(queryCache.getCacheKey()).then((_) => null);
        } else if (query.strategy == constants.rows) {
          return tableStorage.removeBy({'_key': queryCache.getCacheKey()}).then((_) => null);
        } else {
          return new Future.value(null);
        }
      } else {
        storage.IModelStorage modelStorage = query.storage == Some(constants.localStorage) ? factory.localStorage : factory.sessionStorage;
        var tableStorage = modelStorage[query.fullName];
        tableStorage.removeBy({'key':queryCache.getCacheKey()});
        return new Future.value(null);
      }
    } else {
      throw new Exception('The query has no cache.');
    }
  }

  /// Execute the query in terms of status and parameters.
  Future<dynamic> _execute() {
    var mapper = factory.mapper;
    Future<dynamic> result;
    var modelModelStorage = getStorage(query.model.storage);
    var modelTableStorage = modelModelStorage[query.model.name];
    if (query.name == constants.findAll && query.model.hasCache) {
      return prepareFindAllModel().then((_){
        return modelTableStorage.findAll();
      }).then((_) => mapper.toObject(query.model, _));
    } else if (query.name == constants.find && query.model.hasCache && query.model.strategy == Some(constants.table)) {
      return prepareFindAllModel().then((_){
        return modelTableStorage.find(parameters[query.model.keyColumn.name]);
      }).then((_) => mapper.toObject(query.model, _));
    } else if (query.name == constants.find && query.model.hasCache && query.model.strategy == Some(constants.row)) {
      return prepareFindModel().then((_){
        return modelTableStorage.find(parameters[query.model.keyColumn.name]);
      }).then((_) => mapper.toObject(query.model, _));
    } else if (query.remote.isNotDefined) {
      return prepareFindAllModel().then((_){
        return getFromLocalModel();
      }).then((_) => mapper.toObject(query.model, _));
    } else {
      var prepare = callRemote();
      var asMap = true;
      if (query.then.isDefined) {
        var asMap = false;
        prepare = prepare.then((values){
          return nextQuery(values);
        });
      }

      if (query.hasCache) {
        prepare = prepare.then((values){
          var mapValues = asMap ? values : factory.mapper.toJson(query.model, values);
          var modelStorage = getStorage(query.storage);
          var tableStorage = modelStorage[query.fullName + JSON.encode(parameters)];
          if (query.strategy == constants.row) {
            tableStorage.putOne(mapValues[query.model.keyColumn.name], mapValues);
          } else {
            var mapRows = {};
            for (var row in mapValues) {
              mapRows[mapValues[query.model.keyColumn.name]] = row;
            }
            tableStorage.putMany(mapRows);
          }
          return values;
        });
      }

      // When there is not a strategy, we return any result.
      if (query.strategy == constants.none) {
        return prepareFindAllModel().then((_) => null);
      } else {
        return prepare.then((_) => asMap ? factory.mapper.toObject(query.model, _) : _);
      }
    }
  }

  /// Prepares the local cache for the [constants.findAll] query.
  Future prepareFindAllModel() {
    var mapper = factory.mapper;
    var findAllQuery = query.model.getQuery(constants.findAll).get();
    var modelStorage = getStorage(query.model.storage);
    var tableStorage = modelStorage[query.model.name];
    var modelCache = new Cache.model(this, query.model);
    return modelCache.isExpired().then((isExpired){
      if (isExpired) {
        var prepare = new TableStoragePulling(this, tableStorage).pull(findAllQuery, null);
        prepare = prepare.then((result){
          return modelCache.update().then((_){
            return result;
          });
        });
        return prepare;
      } else {
        return new Future.value();
      }
    });
  }

  /// Prepares the local cache for the [constants.find] query.
  Future prepareFindModel() {
    var mapper = factory.mapper;
    var modelStorage = getStorage(query.model.storage);
    var tableStorage = modelStorage[query.model.name];
    var key = parameters[query.model.keyColumn.name];
    var modelCache = new Cache.model(this, query.model, key);
    return modelCache.isExpired().then((isExpired){
      if (isExpired) {
        var prepare = new TableStoragePulling(this, tableStorage).pull(query, parameters);
        prepare = prepare.then((result){
          return modelCache.update().then((_){
            return result;
          });
        });
        return prepare;
      } else {
        return new Future.value();
      }
    });
  }

  /// Returns the result of the query by querying the local storage.
  Future<dynamic> getFromLocalModel() {
    var modelStorage = getStorage(query.model.storage);
    var tableStorage = modelStorage[query.model.name];
    bool constraintMapObject (Map<String, Object> values) {
      var object = factory.mapper.toObject(query.model, values);
      return constraint.get()(object);
    };
    if (constraint.isDefined && parameters.length > 0) {
      if (query.strategy == Some(constants.row)) {
        return tableStorage.findOneFor(parameters, constraintMapObject);
      } else {
        return tableStorage.findManyFor(parameters, constraintMapObject);
      }
    } else if (constraint.isDefined) {
      // parameters.length = 0
      if (query.strategy == Some(constants.row)) {
        return tableStorage.findOneWhen(constraintMapObject);
      } else {
        return tableStorage.findManyWhen(constraintMapObject);
      }
    } else if (parameters.length > 0) {
      // constraint.isNotDefined
      if (query.strategy == Some(constants.row)) {
        return tableStorage.findOneBy(parameters);
      } else {
        return tableStorage.findManyBy(parameters);
      }
    } else {
      // parameters.length = 0 and constraint.isNotDefined
      // query.strategy should always be constants.rows
      return tableStorage.findAll();
    }
  }

  /// Calls the remote url by an AJAX call
  Future<dynamic> callRemote() {
    var request = factory.createRequest();
    request.uri = getUri(query, parameters);
    request.method = query.type;
    if (query.type == constants.post || query.type == constants.put) {
      request.parameters = parameters;
    }
    request.parseResult = query.strategy != constants.none;
    return request.send();
  }

  /// Calls the [Query.then] query with current result and returns its result.
  Future<dynamic> nextQuery(dynamic currentResult) {
    if (query.strategy == constants.column) {
      if (currentResult is List) {
        var rows = currentResult as List<Object>;
        return Future.wait(rows.map((row) {
          return nextQueryByColumn(query, row);
        }));
      } else {
        return nextQueryByColumn(query, currentResult);
      }
    } else if (query.strategy == constants.rows) {
      var rows = currentResult as List<Map<String, Object>>;
      return Future.wait(rows.map((row) {
        return nextQueryByMap(query, row);
      }));
    } else {
      return nextQueryByMap(query, currentResult);
    }
  }

  /// Calls the [Query.then] query with current result and returns its result when the current strategy is [constants.column].
  Future<dynamic> nextQueryByColumn(Query currentQuery, Object columnValue) {
    return em.createQuery(query.model.name, currentQuery.then.get()).then((nextQB){
      nextQB.addParameter(query.model.keyColumn.name, columnValue);
      return nextQB.execute();
    });
  }

  /// Calls the [Query.then] query with current result and returns its result when the current strategy is [constants.row] or [constants.rows].
  Future<dynamic> nextQueryByMap(Query currentQuery, Map<String, Object> parameters) {
    return em.createQuery(query.model.name, currentQuery.then.get()).then((nextQB) {
      nextQB.addParameters(parameters);
      return nextQB.execute();
    });
  }

  /// Returns the query to call in terms of [query.remote] and [parameters].
  String getUri(Query query, Map<String, Object> parameters) {
    return query.remote.map((remote) {
      String uri = config.remoteHost;
      if (!uri.endsWith('/')) {
        uri += '/';
      }
      if (remote.startsWith('/')) {
        uri += remote.substring(1);
      } else {
        uri += remote;
      }
      if (parameters != null) {
        parameters.keys.forEach((key) {
          String value = parameters[key].toString();
          uri = uri.replaceAllMapped(new RegExp(':' + key + '([^a-zA-Z0-9])'), (Match m) => value + '${m[1]}');
          uri = uri.replaceAllMapped(new RegExp(':' + key + '\$'), (Match m) => value);
        });
      }
      log.fine('getUri(${query.remote.get()}, ${JSON.encode(parameters)}) => ${uri}');
      return uri;
    }).getOrElse(() => '');
  }

  /// Returns the storage in terms of its key.
  storage.IModelStorage getStorage(Option<String> storage) {
    if (storage == Some(constants.indexedDB)) {
      return factory.database;
    } else if (storage == Some(constants.localStorage)) {
      return factory.localStorage;
    } else {
      return factory.sessionStorage;
    }
  }
}

/// This class saves the result of a request in one or two storages.
/// It permits to save the result of a query and insert it into model storage too.
class TableStoragePulling {
  storage.ITableStorage tableStorage;
  QueryBuilder queryBuilder;

  TableStoragePulling(this.queryBuilder, this.tableStorage);

  /// Pulls the result of recursive query executions.
  Future pull(Query query, Map<String, Object> parameters) {
    var request = factory.createRequest();
    request.uri = queryBuilder.getUri(query, parameters);
    request.method = query.type;
    return request.send().then((values) {
      if (query.then.isDefined) {
        return nextQuery(query, values);
      } else {
        return save(query, values);
      }
    });
  }

  /// Executes the next query.
  Future nextQuery(Query currentQuery, dynamic currentResult) {
    if (currentQuery.strategy == constants.column) {
      if (currentResult is List) {
        var rows = currentResult as List<Object>;
        return Future.wait(rows.map((row) {
          return nextQueryByColumn(currentQuery, row);
        }));
      } else {
        return nextQueryByColumn(currentQuery, currentResult);
      }
    } else if (currentQuery.strategy == constants.rows) {
      var rows = currentResult as List<Map<String, Object>>;
      return Future.wait(rows.map((row) {
        return nextQueryByMap(currentQuery, row);
      }));
    } else {
      return nextQueryByMap(currentQuery, currentResult);
    }
  }

  /// Executes the next query when current strategy is column.
  Future nextQueryByColumn(Query currentQuery, Object columnValue) {
    return currentQuery.thenQuery.map((nextQuery) {
      return pull(nextQuery, {
          currentQuery.model.keyColumn.name: columnValue
      });
    }).getOrElse(() => new Future.value(null));
  }

  /// Executes the next query when current strategy is row or rows.
  Future nextQueryByMap(Query currentQuery, Map<String, Object> parameters) {
    return currentQuery.thenQuery.map((nextQuery) {
      return pull(nextQuery, parameters);
    }).getOrElse(() => new Future.value(null));
  }

  /// Save the result of given query into current table storage.
  Future save(Query query, dynamic values) {
    var futures = [];
    var keyColumnName = query.model.keyColumn.name;
    if (query.strategy == constants.column) {
      var data = {
          keyColumnName: values
      };
      futures.add(tableStorage.putOne(values, data));
      return Future.wait(futures);
    } else if (query.strategy == constants.row) {
      futures.add(tableStorage.putOne(values[keyColumnName], values));
    } else {
      var data = <Object, Map<String, Object>>{
      };
      (values as List).forEach((row) {
        data[row[keyColumnName]] = row;
      });
      futures.add(tableStorage.putMany(data));
    }
    return Future.wait(futures);
  }
}

/// This class is responsible of the cache system for both model and query.
class Cache {
  QueryBuilder queryBuilder;

  Option<Model> modelOpt;
  Option<Object> keyOpt;

  Option<Query> queryOpt;
  Option<Map<String, Object>> parametersOpt;

  /// Creates a cache system for a model.
  Cache.model(this.queryBuilder, Model model, [Object key]) {
    modelOpt = Some(model);
    keyOpt = new Option(key);
    queryOpt = None;
    parametersOpt = None;
  }

  /// Creates a cache system for a query.
  Cache.query(this.queryBuilder, Query query, [Map<String, Object> parameters]) {
    modelOpt = None;
    keyOpt = None;
    queryOpt = Some(query);
    parametersOpt = new Option(parameters);
  }

  /// Checks if the current cache is expired.
  Future<bool> isExpired() {
    var modelIsExpired = modelOpt.map((model) {
      if (model.hasNotCache) {
        return new Future.value(true);
      } else {
        return _isCacheExpired(getStorage(model.storage), getCacheKey(), model.limit);
      }
    });

    var queryIsExpired = queryOpt.map((query) {
      if (query.hasCache) {
        return new Future.value(true);
      } else {
        return _isCacheExpired(getStorage(query.storage), getCacheKey(), query.limit);
      }
    });

    return modelIsExpired.getOrElse(() => queryIsExpired.get());
  }

  /// Updates the current cache.
  Future update() {
    var updateModel = modelOpt.map((model) {
      if (model.hasNotCache) {
        return new Future.value(null);
      } else {
        return _updateCache(getStorage(model.storage), getCacheKey());
      }
    });
    var updateQuery = queryOpt.map((query) {
      if (query.hasCache) {
        return new Future.value(null);
      } else {
        return _updateCache(getStorage(query.storage), getCacheKey());
      }
    });
    return updateModel.getOrElse(() => updateQuery.get());
  }

  /// Checks if the cache described by its [modelStorage], [key] is expired in terms of its [duration].
  Future<bool> _isCacheExpired(storage.IModelStorage modelStorage, String key, Option<int> duration) {
    return modelStorage['__cache__'].find(key).then((valuesOpt) {
      return valuesOpt.map((cache) {
        return duration.map((duration) {
          var dtStart = new DateTime.fromMillisecondsSinceEpoch(cache['start']);
          var dtExpire = dtStart.add(new Duration(seconds: duration));
          return dtExpire.compareTo(new DateTime.now()) <= 0;
        }).getOrElse(() => false);
      }).getOrElse(() => true);
    });
  }

  /// Updates the cache for in given [modelStorage] and [key].
  Future _updateCache(storage.IModelStorage modelStorage, String key) {
    return modelStorage['__cache__'].putOne(key, {
        'start': new DateTime.now().millisecondsSinceEpoch
    });
  }

  /// Returns the cache key.
  String getCacheKey() {
    var modelKeyOpt = modelOpt.map((Model model){
      var result = model.name;
      if (model.strategy == Some(constants.row) && keyOpt.isDefined) {
        result += '_' + keyOpt.get().toString();
      }
      return result;
    });

    var queryKeyOpt = queryOpt.map((Query query){
      var key = query.fullName;
      if (parametersOpt.isDefined) {
        key += '_' + JSON.encode(parametersOpt.get());
      }
      return key;
    });

    return modelKeyOpt.getOrElse(() => queryKeyOpt.get());
  }

  /// Returns the cache storage.
  storage.IModelStorage getStorage(Option<String> storage) {
    if (storage == Some(constants.indexedDB) || storage == Some(constants.localStorage)) {
      return factory.localStorage;
    } else {
      return factory.sessionStorage;
    }
  }
}