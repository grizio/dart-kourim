part of kourim.storage;

typedef void onDatabaseChange(idb.VersionChangeEvent e);
typedef void processObject(Map<String, Object> values);

/// This interface describes classes which provide some database operations.
abstract class IDatabase {
  /// Before [open] is called, the developer can prepare database changes.
  /// This method adds a change in terms of given [version].
  ///
  ///     // On first version of the database, do "..." operations.
  ///     onChange(1, (event) => ...)
  ///
  /// See [dart.dom.indexed_db.IdbFactory#open] and JavaScript IndexedDB specifications for more information on database changes.
  void onChange(int version, onDatabaseChange callback);

  /// Opens the database.
  /// This will include the whole changes requested by [onChange].
  ///
  /// The considered version of the database will be the maximum version given in [onChange].
  Future open();

  /// Returns an object from given [objectStore] by given [key].
  Future<Option<dynamic>> getObject(String objectStore, Object key);

  /// Remove an object from given [objectStore] with given [key].
  Future removeObject(String objectStore, Object key);

  /// Returns the whole list of data from given [objectStore].
  Future<List<dynamic>> getTableObjectList(String objectStore);

  /// Returns the list of data from given [objectStore] in terms of [keyName] and associated [keyValue].
  ///
  /// The key must be inserted by a function given in [onChange].
  Future<List<dynamic>> getObjectList(String objectStore, String keyName, Object keyValue);

  /// Removes a list of objects from given [objectStore] in terms of [keyName] and associated [keyValue].
  ///
  /// The key must be inserted by a function given in [onChange].
  Future removeObjectList(String objectStore, String keyName, Object keyValue);

  /// Checks if an index defined by its [indexName] exists in given [objectStore].
  Future<bool> hasIndex(String objectStore, String indexName);

  /// Returns the first element in terms of given index.
  /// Because an index can have several values, this method returns only the first one.
  Future<dynamic> getByIndex(String objectStore, String indexName, Object indexValue);

  /// Executes the given [process] for each value in given [objectStore].
  /// **Warning** The resulting data is not saved into object store after processing.
  Future forEachObject(String objectStore, processObject process);

  /// Inserts an object into database.
  ///
  /// * If the [key] is provided, use it as object key.
  /// * In the other case, it will use the inner object key.
  ///
  /// See [dart.dom.indexed_db.ObjectStore#put] for more information.
  Future putObject(String objectStore, Object object, [Object key]);

  /// Puts a list of objects in the database.
  ///
  /// * If the given [objects] are a map, it will call [putObject] with a key.
  /// * If the given [objects] are a collection, it will call [putObject] without a key.
  /// * In other cases, it could generate an exception.
  Future putObjectList(String objectStore, dynamic objects);
}

class Database extends IDatabase {
  final String name;
  Map<int, List<onDatabaseChange>> _changes = {};
  Future<idb.Database> _db;

  Database(this.name);

  @override
  void onChange(int version, onDatabaseChange callback) {
    if (!_changes.containsKey(version)) {
      _changes[version] = [];
    }
    _changes[version].add(callback);
  }

  @override
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

  @override
  Future<Option<dynamic>> getObject(String objectStore, Object key) {
    return _db.then((db){
      var transaction = db.transaction(objectStore, internalConstants.readonly);
      var store = transaction.objectStore(objectStore);
      return new Option(store.getObject(key));
    });
  }

  @override
  Future removeObject(String objectStore, Object key) {
    return _db.then((db){
      var transaction = db.transaction(objectStore, internalConstants.readwrite);
      var store = transaction.objectStore(objectStore);
      return store.delete(key);
    });
  }

  @override
  Future<List<dynamic>> getTableObjectList(String objectStore) {
    return _db.then((db) {
      var transaction = db.transaction(objectStore, internalConstants.readonly);
      var store = transaction.objectStore(objectStore);
      return store.openCursor(autoAdvance: true).asBroadcastStream().map((event) => event.value).toList();
    });
  }

  @override
  Future<List<dynamic>> getObjectList(String objectStore, String keyName, Object keyValue) {
    return _db.then((db) {
      var transaction = db.transaction(objectStore, internalConstants.readonly);
      var store = transaction.objectStore(objectStore);
      var index = store.index(keyName);
      return index.openCursor(autoAdvance: true).asBroadcastStream().map((_) => _.value).toList();
    });
  }

  @override
  Future removeObjectList(String objectStore, String keyName, Object keyValue) {
    return _db.then((db){
      var transaction = db.transaction(objectStore, internalConstants.readwrite);
      var store = transaction.objectStore(objectStore);
      var index = store.index(keyName);
      return index.openCursor(autoAdvance: true).asBroadcastStream().forEach((_) => _.delete());
    });
  }

  @override
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

  @override
  Future<dynamic> getByIndex(String objectStore, String indexName, Object indexValue) {
    return _db.then((db){
      var transaction = db.transaction(objectStore, internalConstants.readonly);
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

  @override
  Future forEachObject(String objectStore, processObject process) {
    return _db.then((db){
      var transaction = db.transaction(objectStore, internalConstants.readonly);
      var store = transaction.objectStore(objectStore);
      return store.openCursor(autoAdvance: true).asBroadcastStream().forEach((_) => process(_.value));
    });
  }

  @override
  Future putObject(String objectStore, Object object, [Object key]) {
    return _db.then((db){
      var transaction = db.transaction(objectStore, internalConstants.readwrite);
      var store = transaction.objectStore(objectStore);
      if (key != null) {
        return store.put(object, key);
      } else {
        return store.put(object);
      }
    });
  }

  @override
  Future putObjectList(String objectStore, dynamic objects) {
    return _db.then((db){
      var transaction = db.transaction(objectStore, internalConstants.readwrite);
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