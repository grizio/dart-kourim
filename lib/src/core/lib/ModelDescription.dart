part of kourim.core.lib;

/// Default implementation of the interface [IModelDescription] used by the system in production mode.
class ModelDescription implements IModelDescription {
  Map<String, IModel> _models = {};

  @override
  Option<IModel> findByName(String name) {
    return new Option(_models[name]);
  }

  @override
  void add(IModel model) {
    _models[model.name] = model;
  }
}

class Model implements IModel {
  String name;
  Map<String, IColumn> columns = {};
  Map<String, IQuery> queries = {};
  Option<String> storage;
  Option<String> strategy;
  Option<int> limit;
  ClassMirror classMirror;

  @override
  bool get hasCache => storage.isDefined;

  @override
  bool get hasNotCache => !hasCache;

  @override
  IColumn get keyColumn {
    for (var column in columns.values) {
      if (column.key) {
        return column;
      }
    }
    return null;
  }

  @override
  void addQuery(IQuery query) {
    queries[query.name] = query;
    query.model = this;
  }

  @override
  void addColumn(IColumn column) {
    columns[column.name] = column;
    column.model = this;
  }

  @override
  Option<IQuery> getQuery(String name) {
    return new Option(queries[name]);
  }

  @override
  Option<IColumn> getColumn(String name) {
    return new Option(columns[name]);
  }

  @override
  IModel copy() {
    var model = new Model();
    model.name = name;
    model.storage = storage;
    model.strategy = strategy;
    model.limit = limit;
    model.classMirror = classMirror;
    model.columns = {};
    model.queries = {};
    columns.forEach((key, column) {
      model.columns[key] = column.copy();
      model.columns[key].model = model;
    });
    queries.forEach((key, query){
      model.queries[key] = query.copy();
      model.queries[key].model = model;
    });
    return model;
  }
}

class Column implements IColumn {
  IModel model;
  String name;
  bool key;
  bool unique;
  VariableMirror variableMirror;

  @override
  IColumn copy() {
    var column = new Column();
    column.model = model;
    column.name = name;
    column.key = key;
    column.unique = unique;
    column.variableMirror = variableMirror;
    return column;
  }
}

class Query implements IQuery {
  IModel model;
  String name;
  Option<String> remote = new Option();
  Option<String> then = new Option();
  String type;
  bool authentication;
  List<String> fields = [];
  Option<dynamic> criteria = new Option();
  Option<String> storage;
  Option<int> limit;
  String strategy;

  @override
  Option<IQuery> get thenQuery {
    return then.map((then) => model.getQuery(then).get());
  }

  @override
  String get fullName => model.name + '.' + name;

  @override
  bool get hasCache => storage.isDefined && type == constants.get;

  @override
  bool get hasNotCache => !hasCache;

  @override
  IQuery copy() {
    var query = new Query();
    query.model = model;
    query.name = name;
    query.remote = remote;
    query.then = then;
    query.type = type;
    query.authentication = authentication;
    query.fields = fields;
    query.criteria = criteria;
    query.storage = storage;
    query.limit = limit;
    query.strategy = strategy;
    return query;
  }
}