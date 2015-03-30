part of kourim.description;

abstract class Table<A> {
  final String _tableName;
  Map<String, Field> _fields = {};
  Field _key = null;
  List<Query> _queries = [];

  Table(this._tableName);

  Field field(String name, {bool unique=false, String type='Object'}) {
    if (_fields.containsKey(name)) {
      throw 'A table cannot have two column with the same name.';
    }
    var field = new Field(name, type, false, unique, this);
    _fields[name] = field;
    return field;
  }

  Field key(String name, {String type='Object'}) {
    if (_key != null) {
      throw 'A table can have only one key.';
    }
    var field = new Field(name, type, true, true, this);
    _key = field;
    return field;
  }

  GetQuery get(String remote) {
    var query = new GetQuery(remote);
    _queries.add(query);
    return _queries;
  }

  PostQuery post(String remote) {
    var query = new PostQuery(remote);
    _queries.add(query);
    return query;
  }

  PutQuery put(String remote) {
    var query = new PutQuery(remote);
    _queries.add(query);
    return query;
  }

  DeleteQuery delete(String remote) {
    var query = new DeleteQuery(remote);
    _queries.add(query);
    return query;
  }

  A fromJson(Map<String, Object> data);

  Map<String, Object> toJson(A data);
}

abstract class FullCachedTable<A> extends Table<A> {
  final IModelStorage _modelStorage;
  final Option<Duration> _duration;
  final Lazy<FindAllQuery> _findAllQuery = lazy(() => new FindAllQuery(loadAll, _modelStorage, _duration, _tableName));

  GetQuery get loadAll; // need to be overridden
  FindAllQuery get findAll => _findAllQuery.value;

  FullCachedTable(this._modelStorage, String tableName, [Duration duration]): super(tableName) {
    _duration = Some(duration);
  }
}

abstract class PartialCachedTable<A> extends Table<A> {
  final IModelStorage _modelStorage;
  final Option<Duration> _duration;
  final Lazy<FindQuery> _findQuery = lazy(() => new FindQuery(loadOne, _modelStorage, _duration, _tableName));

  GetQuery get loadOne; // need to be overridden
  FindQuery get find => _findQuery.value;

  PartialCachedTable(this._modelStorage, String tableName, [Duration duration]): super(tableName) {
    _duration = Some(duration);
  }
}