part of kourim.storage.lib;

/// This class is planned for the usage of [IndexedDB].
class DatabaseTableStorage implements ITableStorage {
  final String _name;
  final Future<idb.Database> db;
  final DatabaseModelStorage modelStorage;

  static const readonly = 'readonly';
  static const readwrite = 'readwrite';

  DatabaseTableStorage(this._name, this.db, this.modelStorage);

  @override
  String get name => _name;

  @override
  Future<Option<Map<String, Object>>> find(Object key) {
    return db.then((db){
      var transaction = db.transaction(name, readonly);
      var store = transaction.objectStore(name);
      return store.getObject(key).then((value) => new Option(value))
        .then((result) => transaction.completed.then((_) => result));
    });
  }

  @override
  Future<Iterable<Map<String, Object>>> findAll() {
    return db.then((db){
      var transaction = db.transaction(name, readonly);
      var store = transaction.objectStore(name);
      return store.openCursor(autoAdvance: true).asBroadcastStream().map((event) => event.value).toList()
        .then((result) => transaction.completed.then((_) => result));
    });
  }

  @override
  Future<Option<Map<String, Object>>> findOneBy(Map<String, Object> parameters) {
    return findOneWhen((Map values){
      var valid = true;
      parameters.forEach((key, value){
        if (!values.containsKey(key) || values[key] != value) {
          valid = false;
        }
      });
      return valid;
    });
  }

  @override
  Future<Iterable<Map<String, Object>>> findManyBy(Map<String, Object> parameters) {
    return findManyWhen((Map values){
      var valid = true;
      parameters.forEach((key, value){
        if (!values.containsKey(key) || values[key] != value) {
          valid = false;
        }
      });
      return valid;
    });
  }

  @override
  Future<Option<Map<String, Object>>> findOneWhen(Constraint constraint) {
    return db.then((db){
      var transaction = db.transaction(name, readonly);
      var store = transaction.objectStore(name);
      return store.openCursor(autoAdvance: true).firstWhere((e) => constraint(e.value)).then((idb.CursorWithValue cwv) => cwv.value)
        .then((result) => transaction.completed.then((_) => result));
    });
  }

  @override
  Future<Iterable<Map<String, Object>>> findManyWhen(Constraint constraint) {
    return db.then((db){
      var transaction = db.transaction(name, readonly);
      var store = transaction.objectStore(name);
      return store.openCursor(autoAdvance: true).where((e) => constraint(e.value)).map((idb.CursorWithValue cwv) => cwv.value).toList()
        .then((result) => transaction.completed.then((_) => result));
    });
  }

  @override
  Future<Option<Map<String, Object>>> findOneFor(Map<String, Object> parameters, Constraint constraint) {
    return findOneWhen((Map values){
      var valid = true;
      parameters.forEach((key, value){
        if (!values.containsKey(key) || values[key] != value) {
          valid = false;
        }
      });
      return valid && constraint(values);
    });
  }

  @override
  Future<Iterable<Map<String, Object>>> findManyFor(Map<String, Object> parameters, Constraint constraint) {
    return findManyWhen((Map values){
      var valid = true;
      parameters.forEach((key, value){
        if (!values.containsKey(key) || values[key] != value) {
          valid = false;
        }
      });
      return valid && constraint(values);
    });
  }

  @override
  Future putOne(Object key, Map<String, Object> value) {
    return db.then((db){
      var transaction = db.transaction(name, readwrite);
      var store = transaction.objectStore(name);
      if (store.keyPath == null) {
        return store.put(value, key).then((_) => transaction.completed);
      } else {
        return store.put(value).then((_) => transaction.completed);
      }
    });
  }

  @override
  Future putMany(Map<Object, Map<String, Object>> values) {
    return db.then((db){
      var transaction = db.transaction(name, readwrite);
      var store = transaction.objectStore(name);
      return Future.wait(values.keys.map((key){
        if (store.keyPath == null) {
          return store.put(values[key], key).then((_) => transaction.completed);
        } else {
          return store.put(values[key]).then((_) => transaction.completed);
        }
      }));
    });
  }

  @override
  Future foreach(ForeachValues process) {
    return db.then((db){
      var transaction = db.transaction(name, readonly);
      var store = transaction.objectStore(name);
      return store.openCursor(autoAdvance: true).forEach((e) => process(e.value)).then((_) => transaction.completed);
    });
  }

  @override
  Future<Iterable<Object>> map(MapValues process) {
    return db.then((db){
      var transaction = db.transaction(name, readonly);
      var store = transaction.objectStore(name);
      return store.openCursor(autoAdvance: true).map((e) => process(e.value)).toList()
        .then((result) => transaction.completed.then((_) => result));
    });
  }

  @override
  Future remove(Object key) {
    return db.then((db){
      var transaction = db.transaction(name, readwrite);
      var store = transaction.objectStore(name);
      return store.delete(key).then((_) => transaction.completed);
    });
  }

  @override
  Future removeBy(Map<String, Object> parameters) {
    return removeWhen((values) {
      var result = true;
      parameters.forEach((key, value) {
        if (!values.containsKey(key) || values[key] != value) {
          result = false;
        }
      });
      return result;
    });
  }

  @override
  Future removeWhen(Constraint constraint) {
    return db.then((db){
      var transaction = db.transaction(name, readwrite);
      var store = transaction.objectStore(name);
      return store.openCursor(autoAdvance: true).forEach((e){
        if (constraint(e.value)) {
          e.delete();
        }
      }).then((_) => transaction.completed);
    });
  }

  @override
  Future clean() {
    return db.then((db){
      var transaction = db.transaction(name, readwrite);
      var store = transaction.objectStore(name);
      store.clear().then((_) => transaction.completed);
    });
  }
}