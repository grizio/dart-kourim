part of kourim.description;

abstract class Table<A> {
  final String _tableName;
  Map<String, Field> _fields = {};
  Field _key = null;
  List<Query> _queries = [];
  final Injector _injector;

  Table(this._injector, this._tableName);

  Field field(String name, {bool unique:false}) {
    if (_fields.containsKey(name)) {
      throw 'A table cannot have two columns with the same name.';
    }
    var field = new Field(this, name, false, unique);
    _fields[name] = field;
    return field;
  }

  Field key(String name) {
    if (_key != null) {
      throw 'A table can have only one key.';
    }
    var field = new Field(this, name, true, true);
    _key = field;
    return field;
  }

  GetQuery get(String remote) {
    var query = new GetQuery(_injector, this, remote, None, None, None, _extractFieldsFromURI(remote));
    _queries.add(query);
    return query;
  }

  PostQuery post(String remote) {
    var query = new PostQuery(_injector, this, remote, _extractFieldsFromURI(remote), []);
    _queries.add(query);
    return query;
  }

  PutQuery put(String remote) {
    var query = new PutQuery(_injector, this, remote, _extractFieldsFromURI(remote), []);
    _queries.add(query);
    return query;
  }

  DeleteQuery delete(String remote) {
    var query = new DeleteQuery(_injector, this, remote, _extractFieldsFromURI(remote));
    _queries.add(query);
    return query;
  }

  A fromJson(Map<String, Object> data);

  Map<String, Object> toJson(A data);

  List<Field> _extractFieldsFromURI(String uri) {
    return new RegExp('{([^}]+)}').allMatches(uri).map((match) {
      var name = match.group(1);
      if (_fields.containsKey(name)) {
        return _fields[name];
      } else {
        throw 'All parameters given in remote url must exist in associated table.';
      }
    });
  }
}

abstract class FullCachedTable<A> extends Table<A> {
  FindAllQuery findAll;
  GetQuery get loadAll; // need to be overridden

  FullCachedTable(Injector injector, String tableName, IModelStorage modelStorage, [Duration duration]): super(injector, tableName) {
    findAll = new FindAllQuery(_injector, this, loadAll, modelStorage[tableName], Some(duration));
  }
}

abstract class PartialCachedTable<A> extends Table<A> {
  FindQuery find;
  GetQuery get loadOne; // need to be overridden

  PartialCachedTable(Injector injector, String tableName, IModelStorage modelStorage, [Duration duration]): super(injector, tableName) {
    find = new FindQuery(_injector, this, loadOne, modelStorage[tableName], Some(duration));
  }
}