part of kourim.storage;

typedef void onDatabaseChange(idb.VersionChangeEvent e);
typedef void processObject(Map<String, Object> values);

class Database {
  final String name;
  Map<int, List<onDatabaseChange>> _changes = {};
  Future<idb.Database> _db;

  Database(this.name);

  void onChange(int version, onDatabaseChange callback) {
    if (!_changes.containsKey(version)) {
      _changes[version] = [];
    }
    _changes[version].add(callback);
  }

  Future open() {
    if (_db == null) {
      // Avoids error when multiple calls on this method
      _db = window.indexedDB.open(
          name,
          version: integerUtilities.max(1, integerUtilities.maxFromList(_changes.keys)),
          onUpgradeNeeded: (idb.VersionChangeEvent event) {
            var db = (event.target as idb.Request).result;
            _changes.keys.forEach((version) {
              if (version > event.oldVersion) {
                _changes[version].forEach((callback) => callback(event));
              }
            });
          });
    }
    return _db.then((_) => null); // Avoids to return the internal _db.
  }

  Future<Option<dynamic>> getObject(String objectStore, Object key) {
    return _db.then((db){
      var transaction = db.transaction(objectStore, InternalConstants.readonly);
      var store = transaction.objectStore(objectStore);
      return new Option(store.getObject(key));
    });
  }

  Future removeObject(String objectStore, Object key) {
    return _db.then((db){
      var transaction = db.transaction(objectStore, InternalConstants.readwrite);
      var store = transaction.objectStore(objectStore);
      return store.delete(key);
    });
  }

  Future<List<dynamic>> getTableObjectList(String objectStore) {
    return _db.then((db) {
      var transaction = db.transaction(objectStore, InternalConstants.readonly);
      var store = transaction.objectStore(objectStore);
      return store.openCursor(autoAdvance: true).asBroadcastStream().map((event) => event.value).toList();
    });
  }

  Future<List<dynamic>> getObjectList(String objectStore, String keyName, Object keyValue) {
    return _db.then((db) {
      var transaction = db.transaction(objectStore, InternalConstants.readonly);
      var store = transaction.objectStore(objectStore);
      var index = store.index(keyName);
      return index.openCursor(autoAdvance: true).asBroadcastStream().map((_) => _.value).toList();
    });
  }

  Future removeObjectList(String objectStore, String keyName, Object keyValue) {
    return _db.then((db){
      var transaction = db.transaction(objectStore, InternalConstants.readwrite);
      var store = transaction.objectStore(objectStore);
      var index = store.index(keyName);
      return index.openCursor(autoAdvance: true).asBroadcastStream().forEach((_) => _.delete());
    });
  }

  Future<bool> hasIndex(String objectStore, String indexName) {
    // TODO: how to find if an index exists without the usage of exceptions?
    return _db.then((db){
      try {
        db.transaction(objectStore).objectStore(objectStore).index(indexName);
        return true;
      } catch (e) {
        return false;
      }
    });
  }

  Future<dynamic> getByIndex(String objectStore, String indexName, Object indexValue) {
    return _db.then((db){
      var transaction = db.transaction(objectStore, InternalConstants.readonly);
      var store = transaction.objectStore(objectStore);
      var index = store.index(indexName);
      return index.openCursor(key: indexValue, autoAdvance: true).asBroadcastStream().map((_) => _.value).toList().then((_) {
        if (_.length == 0) {
          return null;
        } else {
          return _.first;
        }
      });
    });
  }

  Future forEachObject(String objectStore, processObject process) {
    return _db.then((db){
      var transaction = db.transaction(objectStore);
      var store = transaction.objectStore(objectStore);
      return store.openCursor(autoAdvance: true).asBroadcastStream().forEach((_) => process(_.value));
    });
  }

  Future putObject(String objectStore, Object object, [Object key]) {
    return _db.then((db){
      var transaction = db.transaction(objectStore, InternalConstants.readwrite);
      var store = transaction.objectStore(objectStore);
      if (key != null) {
        return store.put(object, key);
      } else {
        return store.put(object);
      }
    });
  }

  Future putObjectList(String objectStore, dynamic objects) {
    return _db.then((db){
      var transaction = db.transaction(objectStore, InternalConstants.readwrite);
      var store = transaction.objectStore(objectStore);
      if (objects is Map) {
        return Future.wait((objects as Map).keys.map((key){
          return store.put(objects[key], key);
        }));
      } else if (objects is List) {
        return Future.wait((objects as List).map((value) {
          return store.put(value);
        }));
      } else {
        throw new Exception("The given values are not a list, nor a map.");
      }
    });
  }
}