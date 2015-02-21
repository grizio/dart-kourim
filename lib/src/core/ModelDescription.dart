part of kourim.core;

class ModelDescription {
  Map<String, Model> _models = {};

  Option<Model> findByName(String name) {
    return new Option(_models[name]);
  }

  void add(Model model) {
    _models[model.name] = model;
  }
}

class Model {
  String name;
  Map<String, Column> columns = {};
  Map<String, Query> queries = {};
  Option<String> storage;
  Option<String> strategy;
  Option<int> limit;
  ClassMirror classMirror;

  bool get hasCache => storage.isDefined();
  bool get hasNotCache => !hasCache;

  Option<Column> get keyColumn {
    for (var column in columns.values) {
      if (column.key) {
        return new Option(column);
      }
    }
    return new Option();
  }

  void addQuery(Query query) {
    queries[query.name] = query;
    query.model = this;
  }

  void addColumn(Column column) {
    columns[column.name] = column;
    column.model = this;
  }

  Option<Query> getQuery(String name) {
    return new Option(queries[name]);
  }

  Option<Column> getColumn(String name) {
    return new Option(columns[name]);
  }

  Map<String, Object> extractKey(Object object) {
    var instanceMirror = reflect(object);
    var values = <String, Object>{};
    columns.values.forEach((column){
      if (column.key) {
        var columnValueMirror = instanceMirror.getField(column.variableMirror.simpleName);
        if (columnValueMirror.hasReflectee) {
          values[column.name] = columnValueMirror.reflectee;
        } else {
          values[column.name] = null;
        }
      }
    });
    return values;
  }
}

class Column {
  Model model;
  String name;
  bool key;
  bool unique;
  VariableMirror variableMirror;
}

class Query {
  Model model;
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

  String get fullName => model.name + '.' + name;
  bool get hasCache => storage.isDefined() && type == root.Constants.get;
  bool get hasNotCache => !hasCache;

  Query copy() {
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