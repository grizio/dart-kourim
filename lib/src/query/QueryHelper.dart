part of kourim.query;

class QueryHelper {
  static String getUri(Query query, Map<String, Object> parameters) {
    return query.remote.match(
        some: (String remote) {
          String uri = Config.remoteHost;
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

  /**
   * Checks if the cache for the query is expired.
   *
   * If the query has no cache configuration nor any cached value, return `true`.
   *
   * @return `true` if the cache is expired (need to be refreshed), otherwise `false`
   */
  static bool isQueryCacheExpired(Query query, Map<String, Object> parameters) {
    if (query.hasCache) {
      return true;
    } else {
      var start;
      var storage = query.storage.get();
      if (storage == Constants.indexedDB || storage == Constants.localStorage) {
        // Permanent storages
        start = window.localStorage[getQueryCacheKey(query, parameters, true)];
      } else {
        // Session storage
        start = window.sessionStorage[getQueryCacheKey(query, parameters, true)];
      }
      if (start == null) {
        return true;
      } else if (query.limit.isDefined()) {
        var dtStart = new DateTime.fromMillisecondsSinceEpoch(start);
        var dtExpire = dtStart.add(new Duration(seconds: query.limit.get()));
        return dtExpire.compareTo(new DateTime.now()) <= 0;
      } else {
        return false;
      }
    }
  }

  /**
   * Checks if the cache for the model is expired.
   *
   * If the model has no cache configuration nor any cached value, return `true`.
   *
   * @return `true` if the cache is expired (need to be refreshed), otherwise `false`
   */
  static bool isModelCacheExpired(Model model, Map<String, Object> parameters) {
    if (model.hasNotCache) {
      return true;
    } else {
      var start;
      var storage = model.storage.get();
      if (storage == Constants.indexedDB || storage == Constants.localStorage) {
        // Permanent storages
        start = window.localStorage[getModelCacheKey(model, parameters, true)];
      } else {
        // Session storage
        start = window.sessionStorage[getModelCacheKey(model, parameters, true)];
      }
      if (start == null) {
        return true;
      } else if (model.limit.isDefined()) {
        var dtStart = new DateTime.fromMillisecondsSinceEpoch(start);
        var dtExpire = dtStart.add(new Duration(seconds: model.limit.get()));
        return dtExpire.compareTo(new DateTime.now()) <= 0;
      } else {
        return false;
      }
    }
  }

  /**
   * The the key used for the current query in terms of parameters.
   *
   * @return The key for the current query
   */
  static String getQueryCacheKey(Query query, Map<String, Object> parameters, [bool withPrefix=false]) {
    if (withPrefix) {
      return InternalConstants.prefixStorage + query.model.name + '_' + query.name + '_' + JSON.encode(parameters);
    } else {
      return query.model.name + '_' + query.name + '_' + JSON.encode(parameters);
    }
  }

  /**
   * The the key used for the current model in terms of parameters.
   *
   * @return The key for the current model
   */
  static String getModelCacheKey(Model model, Map<String, Object> parameters, [bool withPrefix=false]) {
    var result = '';
    if (withPrefix) {
      result += InternalConstants.prefixStorage + model.name;
    }
    if (model.strategy == Constants.row) {
      result += '_' + JSON.encode(parameters);
    }
    return result;
  }

  /**
   * Saves the given object into local storage corresponding of given query.
   */
  static Future saveQuery(Query query, Map<String, Object> parameters, dynamic values) {
    if (query.hasCache) {
      var mapValues = values is Map ? values : Mapper.toJson(query.model, values);
      if (query.storage == Constants.indexedDB) {
        if (mapValues is List) {
          (mapValues as List).forEach((mapValuesOne) => mapValuesOne['_key'] = getQueryCacheKey(query, parameters, true));
          return getDatabase(InternalConstants.database).putObjectList(InternalConstants.queryCacheTable, mapValues);
        } else {
          return getDatabase(InternalConstants.database).putObject(InternalConstants.queryCacheTable, mapValues, getQueryCacheKey(query, parameters));
        }
      } else if (query.storage == Constants.localStorage) {
        return new Future(() => window.localStorage[getQueryCacheKey(query, parameters, true)] = mapValues);
      } else {
        return new Future(() => window.sessionStorage[getQueryCacheKey(query, parameters, true)] = mapValues);
      }
    } else {
      return new Future.value(null);
    }
  }

  /**
   * Saves the given object into local storage corresponding of given model.
   */
  static Future saveModel(Model model, dynamic values) {
    if (model.hasCache) {
      var mapValues = values is Map ? values : Mapper.toJson(model, values);
      if (model.storage.get() == Constants.indexedDB) {
        if (mapValues is List) {
          return getDatabase(Config.databaseName).putObjectList(model.name, mapValues);
        } else {
          return getDatabase(Config.databaseName).putObject(model.name, mapValues);
        }
      } else {
        var storage = model.storage.get() == Constants.localStorage ? window.localStorage : window.sessionStorage;
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

  static String getModelStorageKey(Model model) {
    return Config.databaseName + '_' + model.name;
  }

  /**
   * Returns data from local storage for current query.
   *
   * @return Data from local storage, could be one entry or a list of entries.
   */
  static Future<dynamic> getQueryData(Query query, Map<String, Object> parameters) {
    if (query.storage.isDefined()) {
      if (query.storage == Constants.indexedDB) {
        if (query.strategy == Constants.row) {
          return getDatabase(InternalConstants.database).getObject(InternalConstants.queryCacheTable, getQueryCacheKey(query, parameters)).then((_) {
            return _.map((_) => Mapper.toObject(query.model, _));
          });
        } else if (query.strategy == Constants.rows) {
          return getDatabase(InternalConstants.database).getObjectList(InternalConstants.queryCacheTable, '_key',
                                                                       getQueryCacheKey(query, parameters)).then((_) {
            return _.map((_) => Mapper.toObject(query.model, _));
          });
        } else {
          return new Future.value(new Option());
        }
      } else {
        var storage = query.storage == Constants.localStorage ? window.localStorage : window.sessionStorage;
        var values = storage[getQueryCacheKey(query, parameters, true)];
        if (values == null) {
          return new Future.value(query.strategy == Constants.row ? new Option() : []);
        } else {
          return new Future.value(new Option(Mapper.toObject(query.model, values)));
        }
      }
    } else {
      throw new Exception('The query has no cache.');
    }
  }

  static Future<dynamic> getModelData(Model model, Map<String, Object> parameters, Option<Constraint> constraint) {
    if (model.storage.get() == Constants.indexedDB) {
      return getModelDataIDB(model, parameters, constraint);
    } else if (model.storage.get() == Constants.localStorage) {
      return getModelDataStorage(model, parameters, constraint, window.localStorage);
    } else {
      return getModelDataStorage(model, parameters, constraint, window.sessionStorage);
    }
  }

  static Future<dynamic> getModelDataIDB(Model model, Map<String, Object> parameters, Option<Constraint> constraint) {
    var database = getDatabase(Config.databaseName);
    if (constraint.isDefined()) {
      var result = [];
      return database.forEachObject(model.name, (_) {
        var object = Mapper.toObjectOne(model, _);
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
            result.add(Mapper.toObjectOne(model, values));
          }
        }).then((_) => result);
      }
    }
  }

  static Future<dynamic> getModelDataStorage(Model model, Map<String, Object> parameters, Option<Constraint> constraint, Storage storage) {
    // TODO: could be optimized to fetch data.
    var listStr = storage[getModelStorageKey(model)];
    if (listStr == null) {
      return new Future.value(null);
    } else {
      var list = JSON.decode(listStr) as List;
      if (constraint.isDefined()) {
        return new Future.value(list.retainWhere((_) => constraint.get()(Mapper.toObjectOne(model, _))));
      } else {
        if (parameters.length == 0) {
          return new Future.value(list.map((_) => Mapper.toObjectOne(model, _)));
        } else if (parameters.length == 1 && model.getColumn(parameters.keys.first).get().unique) {
          var key = parameters.keys.first;
          var val = parameters.values.first;
          try {
            return new Future.value(Mapper.toObjectOne(model, list.firstWhere((Map _) => _.containsKey(key) && _[key] == val)));
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
          return new Future.value(list.map((_) => Mapper.toObjectOne(model, _)));
        }
      }
    }
  }

  static bool isValidOne(Map<String, Object> parameters, Map<String, Object> values) {
    for (String key in parameters.keys) {
      if (!values.containsKey(key) || values[key] != parameters[key]) {
        return false;
      }
    }
    return true;
  }

  static Future clean(Query query, Map<String, Object> parameters) {
    if (query.storage.isDefined()) {
      if (query.storage == Constants.indexedDB) {
        if (query.strategy == Constants.row) {
          return
            getDatabase(InternalConstants.database)
            .removeObject(InternalConstants.queryCacheTable, getQueryCacheKey(query, parameters))
            .then((_) => null);
        } else if (query.strategy == Constants.rows) {
          return
            getDatabase(InternalConstants.database)
            .removeObjectList(InternalConstants.queryCacheTable, '_key', getQueryCacheKey(query, parameters))
            .then((_) => null);
        } else {
          return new Future.value(null);
        }
      } else {
        Storage  storage = query.storage == Constants.localStorage ? window.localStorage : window.sessionStorage;
        storage.remove(getQueryCacheKey(query, parameters, true));
        return new Future.value(null);
      }
    } else {
      throw new Exception('The query has no cache.');
    }
  }
}