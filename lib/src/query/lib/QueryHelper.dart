part of kourim.query.lib;

class QueryHelper extends IQueryHelper {
  static final Logger log = new Logger('kourim.query.QueryHelper');

  @override
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

  @override
  Future<bool> isQueryCacheExpired(Query query, Map<String, Object> parameters) {
    return new Cache.query(this, query, parameters).isExpired();
  }

  @override
  Future<bool> isModelCacheExpired(Model model, [Object key]) {
    return new Cache.model(this, model, key).isExpired();
  }

  @override
  String getQueryCacheKey(Query query, Map<String, Object> parameters) {
    return new Cache.query(this, query, parameters).getCacheKey();
  }

  @override
  String getModelCacheKey(Model model, [Object key]) {
    return new Cache.model(this, model, key).getCacheKey();
  }

  @override
  Future clean(Query query, Map<String, Object> parameters) {
    log.fine('Cleaning the query');
    if (query.storage.isDefined) {
      if (query.storage == Some(constants.indexedDB)) {
        var tableStorage = factory.internalDatabase[query.fullName];
        if (query.strategy == constants.row) {
          return tableStorage.remove(getQueryCacheKey(query, parameters)).then((_) => null);
        } else if (query.strategy == constants.rows) {
          return tableStorage.removeBy({'_key': getQueryCacheKey(query, parameters)}).then((_) => null);
        } else {
          return new Future.value(null);
        }
      } else {
        storage.IModelStorage modelStorage = query.storage == Some(constants.localStorage) ? factory.localStorage : factory.sessionStorage;
        var tableStorage = modelStorage[query.fullName];
        tableStorage.removeBy({'key': getQueryCacheKey(query, parameters)});
        return new Future.value(null);
      }
    } else {
      throw new Exception('The query has no cache.');
    }
  }

  @override
  Map<String, Object> getBodyParameters(Query query, Map<String, Object> parameters) {
    if (query.remote.isDefined) {
      var result = {};
      var remote = query.remote.get();
      for (var key in parameters.keys) {
        if (!remote.contains(new RegExp(':' + key + '([^a-zA-Z0-9])')) && !remote.contains(new RegExp(':' + key + '\$'))) {
          result[key] = parameters[key];
        }
      }
      log.fine('getBodyParameters(${query.remote.get()}, ${JSON.encode(parameters)}) => ${JSON.encode(result)}');
      return result;
    } else {
      return parameters;
    }
  }

  @override
  Future pull(Query query, Map<String, Object> parameters, storage.ITableStorage tableStorage, [storage.ITableStorage otherTableStorage]) {
    return new TableStoragePulling(this, tableStorage, otherTableStorage).pull(query, parameters);
  }

  @override
  bool endByFindQuery(Query query) {
    if (query.then.isDefined) {
      return endByFindQuery(query.thenQuery.get());
    } else {
      return query.name == constants.find;
    }
  }

  @override
  storage.IModelStorage getStorage(Option<String> storage) {
    if (storage == Some(constants.indexedDB)) {
      return factory.database;
    } else if (storage == Some(constants.localStorage)) {
      return factory.localStorage;
    } else {
      return factory.sessionStorage;
    }
  }

  @override
  Future prepare(Query query, Map<String, Object> parameters) {
    log.fine('Preparing the query');
    if (query.name == constants.find && query.model.hasCache) {
      return prepareFind(query, parameters);
    } else {
      return prepareOther(query, parameters);
    }
  }

  Future prepareFind(Query query, Map<String, Object> parameters) {
    log.fine('Preparing the query as find query');
    var model = query.model;
    var key = parameters[model.keyColumn.name];
    var value = parameters[key];
    var storage = getStorage(model.storage);
    var table = storage[model.name];
    if (model.strategy == Some(constants.table)) {
      // Table pulling should have been done before.
      return table.find(value);
    } else {
      // model.strategy == row
      var cache = new Cache.model(this, model, value);
      return cache.isExpired().then((isExpired) {
        if (isExpired) {
          log.fine('The query cache is expired');
          // We reuse logic from table pulling
          return new TableStoragePulling(this, table).pull(query, parameters).then((_) {
            cache.update();
          });
        } else {
          return table.find(value);
        }
      });
    }
  }

  Future prepareOther(Query query, Map<String, Object> parameters) {
    log.fine('Preparing the query as classic query');
    if (query.model.hasCache && endByFindQuery(query)) {
      log.fine('The query ends with constant.find and the model has a cache.');
      // We reuse both Pull and find logic.
      var tempModel = query.model.copy();
      var tempQuery = tempModel.getQuery(query.name).get();
      var key = 'tmp_' + query.fullName + JSON.encode(parameters);
      var tableStorage = factory.sessionStorage[key];
      getBeforeFindQuery(tempQuery).then = None;
      return new TableStoragePulling(this, tableStorage).pull(tempQuery, parameters).then((_) {
        return tableStorage.findAll().then((rows) {
          return Future.wait(rows.map((row) {
            return prepareFind(query.model.getQuery(constants.find).get(), row);
          }));
        });
      });
    } else {
      return new TableStoragePulling(this, getStorage(query.storage)[query.fullName + JSON.encode(parameters)]).pull(query, parameters);
    }
  }

  Query getBeforeFindQuery(Query query) {
    if (query.then == Some(constants.find)) {
      return query;
    } else if (query.then.isNotDefined) {
      return null;
    } else {
      return getBeforeFindQuery(query.thenQuery.get());
    }
  }
}

/// This class saves the result of a request in one or two storages.
/// It permits to save the result of a query and insert it into model storage too.
class TableStoragePulling {
  storage.ITableStorage tableStorage;
  Option<storage.ITableStorage> otherTableStorage;
  QueryHelper queryHelper;

  TableStoragePulling(this.queryHelper, this.tableStorage, [storage.ITableStorage otherTableStorage = null]) {
    this.otherTableStorage = new Option(otherTableStorage);
  }

  Future pull(Query query, Map<String, Object> parameters) {
    var request = factory.createRequest();
    request.uri = queryHelper.getUri(query, parameters);
    request.method = query.type;
    return request.send().then((values) {
      if (query.then.isDefined) {
        return nextQuery(query, values);
      } else {
        return save(query, values);
      }
    });
  }

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

  Future nextQueryByColumn(Query currentQuery, Object columnValue) {
    return currentQuery.thenQuery.map((nextQuery) {
      return pull(nextQuery, {
          currentQuery.model.keyColumn.name: columnValue
      });
    }).getOrElse(() => new Future.value(null));
  }

  Future nextQueryByMap(Query currentQuery, Map<String, Object> parameters) {
    return currentQuery.thenQuery.map((nextQuery) {
      return pull(nextQuery, parameters);
    }).getOrElse(() => new Future.value(null));
  }

  Future save(Query query, dynamic values) {
    var futures = [];
    var keyColumnName = query.model.keyColumn.name;
    if (query.strategy == constants.column) {
      var data = {
          keyColumnName: values
      };
      futures.add(tableStorage.putOne(values, data));
      if (otherTableStorage.isDefined) {
        futures.add(otherTableStorage.get().putOne(values, data));
      }
      return Future.wait(futures);
    } else if (query.strategy == constants.row) {
      futures.add(tableStorage.putOne(values[keyColumnName], values));
      if (otherTableStorage.isDefined) {
        futures.add(otherTableStorage.get().putOne(values[keyColumnName], values));
      }
    } else {
      var data = <Object, Map<String, Object>>{
      };
      (values as List).forEach((row) {
        data[row[keyColumnName]] = row;
      });
      futures.add(tableStorage.putMany(data));
      if (otherTableStorage.isDefined) {
        futures.add(otherTableStorage.get().putMany(data));
      }
    }
    return Future.wait(futures);
  }
}

/// This class is responsible of the cache system for both model and query.
class Cache {
  QueryHelper queryHelper;

  Option<Model> modelOpt;
  Option<Object> keyOpt;

  Option<Query> queryOpt;
  Option<Map<String, Object>> parametersOpt;

  Cache.model(this.queryHelper, Model model, [Object key]) {
    modelOpt = Some(model);
    keyOpt = new Option(key);
    queryOpt = None;
    parametersOpt = None;
  }

  Cache.query(this.queryHelper, Query query, [Map<String, Object> parameters]) {
    modelOpt = None;
    keyOpt = None;
    queryOpt = Some(query);
    parametersOpt = new Option(parameters);
  }

  Future<bool> isExpired() {
    var modelIsExpired = modelOpt.map((model) {
      if (model.hasNotCache) {
        return new Future.value(true);
      } else {
        return _isCacheExpired(getStorage(model.storage), queryHelper.getModelCacheKey(model, keyOpt.get()), model.limit);
      }
    });

    var queryIsExpired = queryOpt.map((query) {
      if (query.hasCache) {
        return new Future.value(true);
      } else {
        return _isCacheExpired(getStorage(query.storage), queryHelper.getQueryCacheKey(query, parametersOpt.get()), query.limit);
      }
    });

    return modelIsExpired.getOrElse(() => queryIsExpired.get());
  }

  Future update() {
    var updateModel = modelOpt.map((model) {
      if (model.hasNotCache) {
        return new Future.value(null);
      } else {
        return _updateCache(getStorage(model.storage), queryHelper.getModelCacheKey(model, keyOpt.get()));
      }
    });
    var updateQuery = queryOpt.map((query) {
      if (query.hasCache) {
        return new Future.value(null);
      } else {
        return _updateCache(getStorage(query.storage), queryHelper.getQueryCacheKey(query, parametersOpt.get()));
      }
    });
    return updateModel.getOrElse(() => updateQuery.get());
  }

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

  Future _updateCache(storage.IModelStorage modelStorage, String key) {
    return modelStorage['__cache__'].putOne(key, {
        'start': new DateTime.now()
    });
  }

  String getCacheKey() {
    var modelKeyOpt = modelOpt.map((Model model){
      var result = '';
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

  storage.IModelStorage getStorage(Option<String> storage) {
    if (storage == Some(constants.indexedDB) || storage == Some(constants.localStorage)) {
      return factory.localStorage;
    } else {
      return factory.sessionStorage;
    }
  }
}