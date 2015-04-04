part of kourim.core;

/// Describes a table usable by the system to retrieve data from remote or local storage.
abstract class Table<A> {
  /// The table name
  final String _tableName;

  /// The list of fields of this table
  Map<String, Field> _fields = {};

  /// The key of the table - must be provided
  Field _key = null;

  /// The injector object.
  final Injector _injector;

  /// Initializes the table with [_injector] and [_tableName] provided by child table.
  Table(this._injector, this._tableName);

  /// Creates and adds a field in terms of its [name] and indicates if it is [unique].
  Field field(String name, {bool unique:false}) {
    if (_fields.containsKey(name)) {
      throw 'A table cannot have two columns with the same name.';
    }
    var field = new Field(this, name, false, unique);
    _fields[name] = field;
    return field;
  }

  /// Creates the key in terms of its [name].
  /// Throw an exception when the developper use two keys in its table.
  Field keyField(String name) {
    if (_key != null) {
      throw 'A table can have only one key.';
    }
    var field = new Field(this, name, true, true);
    _key = field;
    _fields[name] = field;
    return field;
  }

  /// Initializes a [GetQuery] with given [remote].
  GetQuery get(String remote) => new GetQuery(_injector, this, remote, None, None, None, _extractFieldsFromURI(remote), []);

  /// Initializes a [PostQuery] with given [remote].
  PostQuery post(String remote) => new PostQuery(_injector, this, remote, _extractFieldsFromURI(remote), []);

  /// Initializes a [PutQuery] with given [remote].
  PutQuery put(String remote) => new PutQuery(_injector, this, remote, _extractFieldsFromURI(remote), []);

  /// Initializes a [DeleteQuery] with given [remote].
  DeleteQuery delete(String remote) => new DeleteQuery(_injector, this, remote, _extractFieldsFromURI(remote));

  /// This method is used to transform a map on JSON format into the wanted object type.
  A fromJson(Map<String, Object> data);

  /// This method is used to transform an object from wanted type into a JSON format map.
  Map<String, Object> toJson(A data);

  /// Extracts the list of fields from the URI.
  List<Field> _extractFieldsFromURI(String uri) {
    return new RegExp('{([^}]+)}').allMatches(uri).map((match) {
      var name = match.group(1);
      if (_fields.containsKey(name)) {
        return _fields[name];
      } else {
        throw 'All parameters given in remote url must exist in associated table.' + name + JSON.encode(_fields.keys);
      }
    }).toList();
  }
}

/// This table must be used when the developer want to save the whole table in local before querying on it.
abstract class FullCachedTable<A> extends Table<A> {
  Lazy<FindAllQuery> _findAll;

  ITableStorage _tableStorage;

  /// This method must be provided by the developer.
  /// It will be used by [findAll] to fetch data before saving them in local storage.
  GetQuery get loadAll;

  /// Special query used to fetch data from local or remote in terms of cache expiration.
  FindAllQuery get findAll => _findAll.value;

  /// Returns a sample (LocalQuery].
  LocalQuery get local => new LocalQuery(_injector, this, _tableStorage, [], [], []);

  FullCachedTable(Injector injector, IModelStorage modelStorage, String tableName, [Duration duration]): super(injector, tableName) {
    _tableStorage = modelStorage[_tableName];
    _findAll = lazy(() => new FindAllQuery(_injector, this, loadAll, _tableStorage, Some(duration), []));
  }
}

/// This table must be used when the developer want to save row by row in local when fetching data from remote.
abstract class PartialCachedTable<A> extends Table<A> {
  Lazy<FindQuery> _find;

  /// This method must be provided by the developer.
  /// It will be used by [find] to fetch data remotely before saving them in local storage.
  GetQuery get loadOne;

  /// Special query used to fetch data from local or remote in terms of cache expiration.
  FindQuery get find => _find.value;

  PartialCachedTable(Injector injector, IModelStorage modelStorage, String tableName, [Duration duration]): super(injector, tableName) {
    _find = lazy(() => new FindQuery(_injector, this, loadOne, modelStorage[tableName], Some(duration), []));
  }
}