part of kourim.core.lib;

class ModelValidation extends IModelValidation {
  @override
  bool validate(IModelDescription modelDescription) {
    //TODO
  }

  bool isFinalAndWrongStrategy(Query query) {
    return query.then.isNotDefined && query.strategy == constants.column;
  }

  bool hasNoRemoteAndNoModelCache(Query query) {
    return query.remote.isNotDefined && query.model.hasNotCache;
  }

  bool hasNextAndWrongStrategy(Query query) {
    return query.then.isDefined && ![constants.rows, constants.column].contains(query.strategy);
  }

  bool isFindAllAndWrongStrategy(Query query) {
    return query.name == constants.findAll && query.strategy != constants.rows && (query.strategy != constants.column || query.then.isNotDefined);
  }

  bool isFindAndWrongStrategy(Query query) {
    return query.name == constants.find && (query.strategy != constants.row || query.then.isDefined);
  }

  bool isUnknownStrategyQuery(String strategy) {
    return [constants.row, constants.rows, constants.column, constants.none].contains(strategy);
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

  bool hasNotOneKey(Model model) {
    bool found = false;
    for (Column column in model.columns) {
      if (column.key) {
        if (found) {
          return true;
        } else {
          found = true;
        }
      }
    }
    return found;
  }

  bool hasModelCacheAndNotFindAll(Model model) {
    return model.hasCache && model.getQuery(constants.findAll).isNotDefined;
  }

  bool isLooping(Query query, [List<String> previous]) {
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
}