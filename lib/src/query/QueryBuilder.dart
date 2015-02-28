part of kourim.query;

typedef bool Constraint(Object object);

/// Defines a query builder which can be parametrized and be executed to fetch data from remote server or local storage.
abstract class IQueryBuilder {
  /// Adds a parameter to the query
  void addParameter(String name, Object value);

  /// Adds a list of parameters to the query.
  void addParameters(Map<String, Object> values);

  /// Gets the constraint that all results in the query must conform to be returned to the user.
  Option<Constraint> get constraint;

  /// Sets the constraint that all results in the query must conform to be returned to the user.
  void setConstraint(Constraint constraint);

  /// Executes the query and return its result.
  /// The resulting data depends on query and model strategies defined with [kourim.annotations].
  Future<dynamic> execute();

  /// Removes local data in terms of given configured query.
  /// It is useful when there is a need to refresh manually a query.
  ///
  /// This method do not make any request to server.
  Future clean();
}

/// This class is the default implementation of IQueryBuilder and is used in production mode.
class QueryBuilder extends IQueryBuilder {
  // TODO: The system use only JSON. See how we can use other formats.

  final Logger log = new Logger('kourim.query.QueryBuilder');

  Query _query;
  IEntityManager em;
  bool isThen;

  Map<String, Object> parameters = {};
  Option<Constraint> _constraint = None;

  QueryBuilder(this._query, this.em, [bool this.isThen=false]);

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
    if (_query.remote.isDefined) {
      if (_query.hasCache) {
        if (factory.queryHelper.isQueryCacheExpired(_query, parameters)) {
          return _prepare().then((_){
            return factory.queryHelper..getQueryData(_query, parameters);
          });
        } else {
          return factory.queryHelper.getQueryData(_query, parameters);
        }
      } else {
        // Use existing logic to get data.
        // Save temporary the result into session.
        var query = _query.copy();
        query.storage = new Option(constants.sessionStorage);
        var queryBuilder = new QueryBuilder(query, em);
        var result = queryBuilder.execute();
        result.then((_) =>  queryBuilder.clean());
        return result;
      }
    } else if (_query.model.hasCache && _query.model.strategy == Some(constants.table)) {
      return _prepare().then((_){
        return factory.queryHelper.getModelData(_query.model, parameters, _constraint);
      });
    } else {
      throw new Exception('Given query has no remote url, nor a model cache as table.');
    }
  }

  /// Prepares the result by fetching it from the server and saving it to a local storage.
  Future _prepare() {
    if (_query.remote.isDefined && _query.hasCache || _query.model.hasCache && _query.model.getQuery(constants.findAll).isDefined) {
      if (_query.hasCache && !factory.queryHelper.isQueryCacheExpired(_query, parameters) ||
          _query.model.hasCache && !factory.queryHelper.isQueryCacheExpired(_query, parameters)) {
        return new Future.value(null); // Already prepared
      } else {
        if (_query.hasCache || isThen) {
          Future<HttpRequest> request;
          var remote = _query.remote.get();
          String uri = factory.queryHelper.getUri(_query, parameters);
          if (_query.type == constants.get) {
            request = HttpRequest.request(uri, method: constants.get);
          } else {
            Map<String, Object> cleanedParameters = factory.queryHelper.getBodyParameters(_query, parameters);
            request = HttpRequest.request(uri, method: _query.type, sendData: JSON.encode(cleanedParameters));
          }
          log.info("get/fetch data from uri '" + uri + "'");
          return request.then((result){
            var values = JSON.decode(result.responseText);
            if (_query.then.isDefined) {
              if (values is List) {
                return Future.wait((values as List).map(_prepareNextOne));
              } else {
                return _prepareNextOne(values);
              }
            } else {
              if (_query.hasCache) {
                return factory.queryHelper.saveQuery(_query, parameters, values);
              } else {
                // model.hasCache
                return factory.queryHelper.saveModel(_query.model, values);
              }
            }
          });
        } else {
          return em.createQuery(_query.model.name, constants.findAll).then((IQueryBuilder _) {
            if (_ is QueryBuilder) {
              QueryBuilder qb = _;
              qb.isThen = true;
              return qb._prepare();
            } else {
              throw 'The system seems to not have a unique implementation for IQueryBuilder.';
            }
          });
        }
      }
    } else {
      throw 'The query ' + _query.fullName + ' has not a remote uri or not a query nor model cache.';
    }
  }

  /// When the query has a [then] attribute, this method is called to prepare the result of [then] query.
  Future _prepareNextOne(dynamic values) {
    // recursive call with usage of QueryBuilder mechanism
    return em.createQuery(_query.model.name, _query.then.get()).then((_){
      if (_ is QueryBuilder) {
        QueryBuilder qbNext = _;
        qbNext.isThen = true;
        if (_query.strategy == constants.rows) {
          qbNext.addParameters(values);
          return qbNext._prepare();
        } else if (_query.strategy == constants.column) {
          if (_query.model.keyColumn.isDefined) {
            qbNext.addParameter(_query.model.keyColumn.get().name, values);
            return qbNext._prepare();
          } else {
            throw 'Queries with a then value and a strategy as Constant.column must have a key column.';
          }
        } else {
          throw 'Queries with a then value must have a strategy as Constants.rows or Constants.column.';
        }
      } else {
        throw 'The system seems to not have a unique implementation for IQueryBuilder.';
      }
    });
  }

  @override
  Future clean() {
    return factory.queryHelper.clean(_query, parameters);
  }
}