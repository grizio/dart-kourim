part of kourim.query.lib;

/// This class is the default implementation of IQueryBuilder and is used in production mode.
class QueryBuilder extends IQueryBuilder {
  // TODO: The system uses only JSON. See how we can use other formats.

  static final Logger log = new Logger('kourim.query.QueryBuilder');

  Query query;
  IEntityManager em;
  bool isThen;

  Map<String, Object> parameters = {
  };
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

  Future<dynamic> _execute() {
    var queryHelper = factory.queryHelper;
    if (query.hasCache) {
      log.fine('The query has a cache.');
      return queryHelper.isQueryCacheExpired(query, parameters).then((isExpired) {
        Future prepare;
        if (isExpired) {
          log.fine('The cache query is expired.');
          if (queryHelper.endByFindQuery(query) && query.model.hasCache && query.model.strategy == Some(constants.table)) {
            log.fine('The query ends with constants.find and the model has a table cache.');
            prepare = queryHelper.isModelCacheExpired(query.model, parameters[query.model.keyColumn.name]).then((isExpired) {
              if (isExpired) {
                log.fine('The model cache is expired.');
                var queryFindAll = query.model.getQuery(constants.findAll).get();
                var tableStorage = queryHelper.getStorage(query.model.storage)[query.model.name];
                return queryHelper.pull(queryFindAll, null, tableStorage);
              } else {
                return new Future.value();
              }
            });
          } else {
            prepare = new Future.value();
          }
          prepare = prepare.then((_) {
            return queryHelper.prepare(query, parameters);
          });
        }
        return prepare.then((_) {
          return queryHelper.getStorage(query.storage)[queryHelper.getQueryCacheKey(query, parameters)].findAll();
        });
      });
    } else if (query.model.hasCache && query.model.strategy == Some(constants.table)) {
      log.fine('The model has a table cache.');
      return queryHelper.isModelCacheExpired(query.model).then((isExpired) {
        var modelStorage = queryHelper.getStorage(query.model.storage);
        var tableStorage = modelStorage[query.model.name];
        Future prepare;
        if (isExpired) {
          log.fine('The cache is expired.');
          var queryFindAll = query.model.getQuery(constants.findAll).get();
          prepare = queryHelper.pull(queryFindAll, null, tableStorage);
        }
        return prepare.then((_) {
          return loadFromLocal(tableStorage).then((_) => factory.mapper.toObject(query.model, _));
        });
      });
    } else {
      log.fine('The query and the model have not an usable cache.');
      return queryHelper.prepare(query, parameters).then((_) {
        return queryHelper.getStorage(query.storage)[queryHelper.getQueryCacheKey(query, parameters)].findAll();
      });
    }
  }

  Future<dynamic> loadFromLocal(storage.ITableStorage tableStorage) {
    log.fine('Loading from cache.');
    var mapper = factory.mapper;
    var fConstraint = (values) => constraint.get()(mapper.toObjectOne(query.model, values));
    if (query.strategy == constants.rows) {
      if (parameters.length == 0 && constraint.isDefined) {
        return tableStorage.findManyWhen(fConstraint);
      } else if (parameters.length > 0 && constraint.isNotDefined) {
        return tableStorage.findManyBy(parameters);
      } else {
        return tableStorage.findManyFor(parameters, fConstraint);
      }
    } else if (query.strategy == constants.row) {
      if (parameters.length == 0 && constraint.isDefined) {
        return tableStorage.findOneWhen(fConstraint);
      } else if (parameters.length > 0 && constraint.isNotDefined) {
        return tableStorage.findOneBy(parameters);
      } else {
        return tableStorage.findOneFor(parameters, fConstraint);
      }
    } else {
      throw 'An end query (without any "then") should have a "row" or "rows" strategy.';
    }
  }

  @override
  Future clean() {
    return factory.queryHelper.clean(query, parameters);
  }
}