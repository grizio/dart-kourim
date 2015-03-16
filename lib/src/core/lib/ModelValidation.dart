part of kourim.core.lib;

class ModelValidation implements IModelValidation {
  List<String> _errors;

  @override
  bool validate(IModelDescription modelDescription) {
    _errors = [];
    for (var modelName in modelDescription.modelNames) {
      var model = modelDescription.findByName(modelName).get();
      if (hasNotOneKey(model) && !model.isNestedOnly) {
          _errors.add('The model "' + modelName + '" must have one and only one key or be @nestedOnly.');
      }
      if (hasModelCacheAndNotFindAll(model)) {
        _errors.add('The model "' + modelName + '" has a model cache but has not a "findall" query.');
      }
      if (model.strategy.isDefined && isUnknownStrategyModel(model.strategy.get())) {
        _errors.add('The model "' + model.name + '" has an unknown strategy "' + model.strategy.get() + '".');
      }
      if (model.storage.isDefined && isUnknownStorage(model.storage.get())) {
        _errors.add('The model "' + model.name + '" has an unknown storage "' + model.storage.get() + '"');
      }
      if (model.isNestedOnly && model.hasCache) {
        _errors.add('The model "' + model.name + '" is @nestedOnly but also have a cache.');
      }
      if (model.isNestedOnly && model.queryNames.isNotEmpty) {
        _errors.add('The model "' + model.name + '" is @nestedOnly but also have queries.');
      }

      for (var queryName in model.queryNames) {
        var query = model.getQuery(queryName).get();
        if (isFinalAndWrongStrategy(query)) {
          _errors.add('The query "' + query.fullName + '" has not a then query and the strategy "' + query.strategy + '" is not authorized.');
        }
        if (hasNoRemoteAndNoModelCache(query)) {
          _errors.add('The query "' + query.fullName + '" has no remote query and its model does not have a cache.');
        }
        if (hasNextAndWrongStrategy(query)) {
          _errors.add('The query "' + query.fullName + '" has a then but the strategy "' + query.strategy + '" is not authorized in this case.');
        }
        if (isFindAllAndWrongStrategy(query)) {
          _errors.add('The query "' + query.fullName + '" is a special query that does not accept strategy "' + query.strategy + '".');
        }
        if (isFindAndWrongStrategy(query)) {
          _errors.add('The query "' + query.fullName + '" is a special query that does not accept strategy "' + query.strategy + '".');
        }
        if (isUnknownStrategyQuery(query.strategy)) {
          _errors.add('The query "' + query.fullName + '" has an unknown strategy "' + query.strategy + '".');
        }
        if (query.storage.isDefined && isUnknownStorage(query.storage.get())) {
          _errors.add('The query "' + query.fullName + '" has an unknown storage "' + query.storage.get() + '"');
        }
        if (isUnknownMethod(query.type)) {
          _errors.add('The query "' + query.fullName + '" has an unkown type "' + query.type + '"');
        }
        if (isLooping(query)) {
          _errors.add('The query "' + query.fullName + '" is into a query loop (by then calls)');
        }
        if (isFindWithQueryCacheAndModelCache(query)) {
          _errors.add('The query "' + query.fullName + '" has both query cache and model cache.');
        }
        if (hasNoRemoteAndThen(query)) {
          _errors.add('The query "' + query.fullName + '" has not a remote url, but has a then query.');
        }
        if (hasNoneStrategyAndNoRemote(query)) {
          _errors.add('The query "' + query.fullName + '" has "none" strategy and no remote.');
        }
        if (hasNoneStrategyAndGetType(query)) {
          _errors.add('The query "' + query.fullName + '" has "none" strategy but also "get" type.');
        }
        if (hasNoneStrategyAndThen(query)) {
          _errors.add('The query "' + query.fullName + '" has "none" strategy but also "then" query.');
        }
        if (hasNoneStrategyAndQueryCache(query)) {
          _errors.add('The query "' + query.fullName + '" has "none" strategy but also a query cache.');
        }
      }

      for (var columnName in model.columnNames) {
        var column = model.getColumn(columnName).get();
        if (nestedModelNotFound(modelDescription, column)) {
          _errors.add('The column "' + column.fullName + '" has a nested column referencing an unknown model.');
        }
      }
    }
    return _errors.isEmpty;
  }

  @override
  Iterable<String> get errors => _errors;

  bool isFinalAndWrongStrategy(IQuery query) {
    return query.then.isNotDefined && query.strategy == constants.column;
  }

  bool hasNoRemoteAndNoModelCache(IQuery query) {
    return query.remote.isNotDefined && query.model.hasNotCache;
  }

  bool hasNextAndWrongStrategy(IQuery query) {
    return query.then.isDefined && ![constants.rows, constants.column].contains(query.strategy);
  }

  bool isFindAllAndWrongStrategy(IQuery query) {
    return query.name == constants.findAll && query.strategy != constants.rows && (query.strategy != constants.column || query.then.isNotDefined);
  }

  bool isFindAndWrongStrategy(IQuery query) {
    return query.name == constants.find && (query.strategy != constants.row || query.then.isDefined);
  }

  bool isUnknownStrategyQuery(String strategy) {
    return ![constants.row, constants.rows, constants.column, constants.none].contains(strategy);
  }

  bool isUnknownStrategyModel(String strategy) {
    return ![constants.table, constants.row].contains(strategy);
  }

  bool isUnknownStorage(String storage) {
    return ![constants.indexedDB, constants.sessionStorage, constants.localStorage].contains(storage);
  }

  bool isUnknownMethod(String method) {
    return ![constants.get, constants.post, constants.put, constants.delete].contains(method);
  }

  bool hasNotOneKey(IModel model) {
    bool found = false;
    for (Column column in model.columns.values) {
      if (column.key) {
        if (found) {
          return true;
        } else {
          found = true;
        }
      }
    }
    return !found;
  }

  bool hasModelCacheAndNotFindAll(IModel model) {
    return model.hasCache && model.getQuery(constants.findAll).isNotDefined;
  }

  bool isLooping(IQuery query, [List<String> previous]) {
    previous = previous == null ? [] : previous;
    if (previous.contains(query.name)) {
      return true;
    } else if (query.then.isNotDefined) {
      return false;
    } else {
      previous.add(query.name);
      var nextQueryOpt = query.thenQuery;
      if (nextQueryOpt.isNotDefined) {
        return false;
      } else {
        return isLooping(nextQueryOpt.get(), previous);
      }
    }
  }

  bool isFindWithQueryCacheAndModelCache(IQuery query) {
    return query.name == constants.find && query.hasCache && query.model.hasCache;
  }

  bool hasNoRemoteAndThen(IQuery query) {
    return query.remote.isNotDefined && query.then.isDefined;
  }

  bool hasNoneStrategyAndNoRemote(IQuery query) {
    return query.strategy == constants.none && query.remote.isNotDefined;
  }

  bool hasNoneStrategyAndGetType(IQuery query) {
    return query.strategy == constants.none && query.type == constants.get;
  }

  bool hasNoneStrategyAndThen(IQuery query) {
    return query.strategy == constants.none && query.then.isDefined;
  }

  bool hasNoneStrategyAndQueryCache(IQuery query) {
    return query.strategy == constants.none && query.hasCache;
  }

  bool nestedModelNotFound(IModelDescription modelDescription, IColumn column) {
    return column.isModelDescription && modelDescription.findByName(column.type).isNotDefined;
  }
}