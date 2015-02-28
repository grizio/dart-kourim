part of kourim.query;

/// This interface describes classes which implement methods about queries.
abstract class IQueryHelper {
  String getUri(Query query, Map<String, Object> parameters);

  /// Checks if the cache for the query is expired.
  ///
  /// If the query has no cache configuration nor any cached value, return `true`.
  bool isQueryCacheExpired(Query query, Map<String, Object> parameters);

  /// Checks if the cache for the model is expired.
  ///
  /// If the model has no cache configuration nor any cached value, return `true`.
  bool isModelCacheExpired(Model model, Map<String, Object> parameters);

  /// The the key used for the current query in terms of parameters.
  String getQueryCacheKey(Query query, Map<String, Object> parameters, [bool withPrefix=false]);

  /// The the key used for the current model in terms of parameters.
  String getModelCacheKey(Model model, Map<String, Object> parameters, [bool withPrefix=false]);

  /// Saves the given object into local storage corresponding of given query.
  Future saveQuery(Query query, Map<String, Object> parameters, dynamic values);

  /// Saves the given object into local storage corresponding of given model.
  Future saveModel(Model model, dynamic values);

  /// Returns the key for the model used when storing data in [sessionStorage] or [localStorage].
  String getModelStorageKey(Model model);

  /// Returns data from local storage for given query.
  Future<dynamic> getQueryData(Query query, Map<String, Object> parameters);

  /// Returns the data in terms of [model] configuration.
  Future<dynamic> getModelData(Model model, Map<String, Object> parameters, Option<Constraint> constraint);

  /// Removes data in terms of given [query] and [parameters].
  Future clean(Query query, Map<String, Object> parameters);

  /// Returns parameters which should be inserted into a body [HttpRequest].
  /// It actually remove parameters which were already set in query url.
  Map<String, Object> getBodyParameters(Query query, Map<String, Object> parameters);
}

class QueryHelper extends IQueryHelper {
  @override
  String getUri(Query query, Map<String, Object> parameters) {
    return query.remote.match(
        some: (String remote) {
          String uri = config.remoteHost;
          if (!uri.endsWith('/')) {
            uri += '/';
          }
          if (remote.startsWith('/')) {
            uri += remote.substring(1);
          } else {
            uri += remote;
          }
          parameters.keys.forEach((key) {
            String value = parameters[key].toString();
            uri = uri.replaceAllMapped(new RegExp(':' + key + '([^a-zA-Z0-9])'), (Match m) => value + '${m[1]}');
            uri = uri.replaceAllMapped(new RegExp(':' + key + '\$'), (Match m) => value);
          });
          return uri;
        },
        none: () => ''
        );
  }

  @override
  bool isQueryCacheExpired(Query query, Map<String, Object> parameters) {
    if (query.hasCache) {
      return true;
    } else {
      var start;
      var storage = query.storage.get();
      if (storage == constants.indexedDB || storage == constants.localStorage) {
        // Permanent storages
        start = window.localStorage[getQueryCacheKey(query, parameters, true)];
      } else {
        // Session storage
        start = window.sessionStorage[getQueryCacheKey(query, parameters, true)];
      }
      if (start == null) {
        return true;
      } else if (query.limit.isDefined) {
        var dtStart = new DateTime.fromMillisecondsSinceEpoch(start);
        var dtExpire = dtStart.add(new Duration(seconds: query.limit.get()));
        return dtExpire.compareTo(new DateTime.now()) <= 0;
      } else {
        return false;
      }
    }
  }

  @override
  bool isModelCacheExpired(Model model, Map<String, Object> parameters) {
    if (model.hasNotCache) {
      return true;
    } else {
      var start;
      var storage = model.storage.get();
      if (storage == constants.indexedDB || storage == constants.localStorage) {
        // Permanent storages
        start = window.localStorage[getModelCacheKey(model, parameters, true)];
      } else {
        // Session storage
        start = window.sessionStorage[getModelCacheKey(model, parameters, true)];
      }
      if (start == null) {
        return true;
      } else if (model.limit.isDefined) {
        var dtStart = new DateTime.fromMillisecondsSinceEpoch(start);
        var dtExpire = dtStart.add(new Duration(seconds: model.limit.get()));
        return dtExpire.compareTo(new DateTime.now()) <= 0;
      } else {
        return false;
      }
    }
  }

  @override
  String getQueryCacheKey(Query query, Map<String, Object> parameters, [bool withPrefix=false]) {
    if (withPrefix) {
      return internalConstants.prefixStorage + query.model.name + '_' + query.name + '_' + JSON.encode(parameters);
    } else {
      return query.model.name + '_' + query.name + '_' + JSON.encode(parameters);
    }
  }

  @override
  String getModelCacheKey(Model model, Map<String, Object> parameters, [bool withPrefix=false]) {
    var result = '';
    if (withPrefix) {
      result += internalConstants.prefixStorage + model.name;
    }
    if (model.strategy == constants.row) {
      result += '_' + JSON.encode(parameters);
    }
    return result;
  }

  @override
  Future saveQuery(Query query, Map<String, Object> parameters, dynamic values) {
    if (query.hasCache) {
      var mapValues = values is Map ? values : factory.mapper.toJson(query.model, values);
      if (query.storage == constants.indexedDB) {
        if (mapValues is List) {
          (mapValues as List).forEach((mapValuesOne) => mapValuesOne['_key'] = getQueryCacheKey(query, parameters, true));
          return factory.internalDatabase.putObjectList(internalConstants.queryCacheTable, mapValues);
        } else {
          return factory.internalDatabase.putObject(internalConstants.queryCacheTable, mapValues, getQueryCacheKey(query, parameters));
        }
      } else if (query.storage == constants.localStorage) {
        return new Future(() => window.localStorage[getQueryCacheKey(query, parameters, true)] = mapValues);
      } else {
        return new Future(() => window.sessionStorage[getQueryCacheKey(query, parameters, true)] = mapValues);
      }
    } else {
      return new Future.value(null);
    }
  }

  @override
  Future saveModel(Model model, dynamic values) {
    if (model.hasCache) {
      var mapValues = values is Map ? values : factory.mapper.toJson(model, values);
      if (model.storage.get() == constants.indexedDB) {
        if (mapValues is List) {
          return factory.database.putObjectList(model.name, mapValues);
        } else {
          return factory.database.putObject(model.name, mapValues);
        }
      } else {
        var storage = model.storage.get() == constants.localStorage ? window.localStorage : window.sessionStorage;
        var listStr = storage[getModelStorageKey(model)];
        List list;
        if (listStr == null) {
          list = [];
        } else {
          list = JSON.decode(listStr);
        }
        if (mapValues is List) {
          list.addAll(mapValues);
        } else {
          list.add(mapValues);
        }
        storage[getModelStorageKey(model)] = JSON.encode(list);
        return new Future.value(null);
      }
    } else {
      return new Future.value(null);
    }
  }

  @override
  String getModelStorageKey(Model model) {
    return config.databaseName + '_' + model.name;
  }

  @override
  Future<dynamic> getQueryData(Query query, Map<String, Object> parameters) {
    if (query.storage.isDefined) {
      if (query.storage == constants.indexedDB) {
        if (query.strategy == constants.row) {
          return factory.internalDatabase.getObject(internalConstants.queryCacheTable, getQueryCacheKey(query, parameters)).then((_) {
            return _.map((_) => factory.mapper.toObject(query.model, _));
          });
        } else if (query.strategy == constants.rows) {
          return factory.internalDatabase.getObjectList(internalConstants.queryCacheTable, '_key',
                                                                       getQueryCacheKey(query, parameters)).then((_) {
            return _.map((_) => factory.mapper.toObject(query.model, _));
          });
        } else {
          return new Future.value(new Option());
        }
      } else {
        var storage = query.storage == constants.localStorage ? window.localStorage : window.sessionStorage;
        var values = storage[getQueryCacheKey(query, parameters, true)];
        if (values == null) {
          return new Future.value(query.strategy == constants.row ? new Option() : []);
        } else {
          return new Future.value(new Option(factory.mapper.toObject(query.model, values)));
        }
      }
    } else {
      throw new Exception('The query has no cache.');
    }
  }

  @override
  Future<dynamic> getModelData(Model model, Map<String, Object> parameters, Option<Constraint> constraint) {
    if (model.storage.get() == constants.indexedDB) {
      return getModelDataIDB(model, parameters, constraint);
    } else if (model.storage.get() == constants.localStorage) {
      return getModelDataStorage(model, parameters, constraint, window.localStorage);
    } else {
      return getModelDataStorage(model, parameters, constraint, window.sessionStorage);
    }
  }

  /// Returns the data in terms of [model] configuration from [IndexedDB].
  Future<dynamic> getModelDataIDB(Model model, Map<String, Object> parameters, Option<Constraint> constraint) {
    var database = factory.database;
    if (constraint.isDefined) {
      var result = [];
      return database.forEachObject(model.name, (_) {
        var object = factory.mapper.toObjectOne(model, _);
        if (constraint.get()(object)) {
          result.add(object);
        }
      }).then((_) => result);
    } else {
      if (parameters.length == 0) {
        return database.getTableObjectList(model.name);
      } else if (parameters.length == 1 && database.hasIndex(model.name, parameters.keys.first)) {
        return database.getByIndex(model.name, parameters.keys.first, parameters.values.first);
      } else {
        var result = [];
        return database.forEachObject(model.name, (Map<String, Object> values) {
          if (isValidOne(parameters, values)) {
            result.add(factory.mapper.toObjectOne(model, values));
          }
        }).then((_) => result);
      }
    }
  }

  /// Returns the data in terms of [model] configuration from [localStorage] or [sessionStorage].
  Future<dynamic> getModelDataStorage(Model model, Map<String, Object> parameters, Option<Constraint> constraint, Storage storage) {
    // TODO: could be optimized to fetch data.
    var listStr = storage[getModelStorageKey(model)];
    if (listStr == null) {
      return new Future.value(null);
    } else {
      var list = JSON.decode(listStr) as List;
      if (constraint.isDefined) {
        return new Future.value(list.retainWhere((_) => constraint.get()(factory.mapper.toObjectOne(model, _))));
      } else {
        if (parameters.length == 0) {
          return new Future.value(list.map((_) => factory.mapper.toObjectOne(model, _)));
        } else if (parameters.length == 1 && model.getColumn(parameters.keys.first).get().unique) {
          var key = parameters.keys.first;
          var val = parameters.values.first;
          try {
            return new Future.value(factory.mapper.toObjectOne(model, list.firstWhere((Map _) => _.containsKey(key) && _[key] == val)));
          } catch (e) {
            return new Future.value(null);
          }
        } else {
          list.retainWhere((Map values) {
            for (var key in parameters.keys) {
              if (!values.containsKey(key) || values[key] != parameters[key]) {
                return false;
              }
            }
            return true;
          });
          return new Future.value(list.map((_) => factory.mapper.toObjectOne(model, _)));
        }
      }
    }
  }

  /// Checks if the given [values] is valid in terms given [parameters].
  bool isValidOne(Map<String, Object> parameters, Map<String, Object> values) {
    for (String key in parameters.keys) {
      if (!values.containsKey(key) || values[key] != parameters[key]) {
        return false;
      }
    }
    return true;
  }

  @override
  Future clean(Query query, Map<String, Object> parameters) {
    if (query.storage.isDefined) {
      if (query.storage == constants.indexedDB) {
        if (query.strategy == constants.row) {
          return
            factory.internalDatabase
            .removeObject(internalConstants.queryCacheTable, getQueryCacheKey(query, parameters))
            .then((_) => null);
        } else if (query.strategy == constants.rows) {
          return
            factory.internalDatabase
            .removeObjectList(internalConstants.queryCacheTable, '_key', getQueryCacheKey(query, parameters))
            .then((_) => null);
        } else {
          return new Future.value(null);
        }
      } else {
        Storage  storage = query.storage == constants.localStorage ? window.localStorage : window.sessionStorage;
        storage.remove(getQueryCacheKey(query, parameters, true));
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
      return result;
    } else {
      return parameters;
    }
  }
}