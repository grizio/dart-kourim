part of kourim.query;

typedef bool Constraint(Object object);

class QueryBuilder {
  // TODO: The sysetm use only JSON. See how we can use other formats.

  final Logger log = new Logger('kourim.query.QueryBuilder');

  Query _query;
  EntityManager _em;
  bool _isThen;

  Map<String, Object> _parameters = {
  };
  Option<Constraint> _constraint = new Option();

  QueryBuilder(this._query, this._em, [bool this._isThen=false]);

  void addParameter(String name, Object value) {
    _parameters[name] = value;
  }

  void addParameters(Map<String, Object> values) {
    values.keys.forEach((key) => addParameter(key, values[key]));
  }

  void set constraint(Constraint constraint) {
    _constraint = new Option(constraint);
  }

  Future<dynamic> execute() {
    if (_query.remote.isDefined()) {
      if (_query.hasCache) {
        if (QueryHelper.isQueryCacheExpired(_query, _parameters)) {
          return _prepare().then((_){
            return QueryHelper.getQueryData(_query, _parameters);
          });
        } else {
          return QueryHelper.getQueryData(_query, _parameters);
        }
      } else {
        // Use existing logic to get data.
        // Save temporary the result into session.
        var query = _query.copy();
        query.storage = new Option(Constants.sessionStorage);
        var queryBuilder = new QueryBuilder(query, _em);
        var result = queryBuilder.execute();
        result.then((_) =>  queryBuilder.clean());
        return result;
      }
    } else if (_query.model.hasCache && _query.model.strategy.isDefined() && _query.model.strategy.get() == Constants.table) {
      return _prepare().then((_){
        return QueryHelper.getModelData(_query.model, _parameters, _constraint);
      });
    } else {
      throw new Exception('Given query has no remote url, nor a model cache as table.');
    }
  }

  Future _prepare() {
    if (_query.remote.isDefined() && _query.hasCache || _query.model.hasCache && _query.model.getQuery(Constants.findAll).isDefined()) {
      if (_query.hasCache && !QueryHelper.isQueryCacheExpired(_query, _parameters) ||
          _query.model.hasCache && !QueryHelper.isQueryCacheExpired(_query, _parameters)) {
        return new Future.value(null); // Already prepared
      } else {
        if (_query.hasCache || _isThen) {
          Future<HttpRequest> request;
          var remote = _query.remote.get();
          String uri = QueryHelper.getUri(_query, _parameters);
          if (_query.type == Constants.get) {
            request = HttpRequest.request(uri, method: Constants.get);
          } else {
            Map<String, Object> cleanedParameters = QueryHelper.getBodyParameters(_query, _parameters);
            request = HttpRequest.request(uri, method: _query.type, sendData: JSON.encode(cleanedParameters));
          }
          log.info("get/fetch data from uri '" + uri + "'");
          return request.then((result){
            var values = JSON.decode(result.responseText);
            if (_query.then.isDefined()) {
              if (values is List) {
                return Future.wait((values as List).map(_prepareNextOne));
              } else {
                return _prepareNextOne(values);
              }
            } else {
              if (_query.hasCache) {
                return QueryHelper.saveQuery(_query, _parameters, values);
              } else {
                // model.hasCache
                return QueryHelper.saveModel(_query.model, values);
              }
            }
          });
        } else {
          return _em.createQuery(_query.model.name, Constants.findAll).then((QueryBuilder _) {
            _._isThen = true;
            return _._prepare();
          });
        }
      }
    } else {
      throw new Exception('The query ' + _query.fullName + ' has not a remote uri or not a query nor model cache.');
    }
  }

  Future _prepareNextOne(dynamic values) {
    // recursive call with usage of QueryBuilder mechanism
    return _em.createQuery(_query.model.name, _query.then.get()).then((qbNext){
      qbNext._isThen = true;
      if (_query.strategy == Constants.rows) {
        qbNext.addParameters(values);
        return qbNext._prepare();
      } else if (_query.strategy == Constants.column) {
        if (_query.model.keyColumn.isDefined()) {
          qbNext.addParameter(_query.model.keyColumn.get().name, values);
          return qbNext._prepare();
        } else {
          throw new Exception('Queries with a then value and a strategy as Constant.column must have a key column.');
        }
      } else {
        throw new Exception('Queries with a then value must have a strategy as Constants.rows or Constants.column.');
      }
    });
  }

  Future clean() {
    return QueryHelper.clean(_query, _parameters);
  }
}