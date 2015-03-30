part of kourim.storage.lib;

/// This class is planned for the usage of [IndexedDB].
class DatabaseModelStorage implements IDatabase {
  final String name;
  Future<idb.Database> db;
  Map<int, List<OnDatabaseChange>> changes = {};

  Map<String, DatabaseTableStorage> tableStorageMap = {};

  DatabaseModelStorage(this.name);

  @override
  void onChange(int version, OnDatabaseChange callback) {
    if (!changes.containsKey(version)) {
      changes[version] = [];
    }
    changes[version].add(callback);
  }

  @override
  Future open() {
    if (db == null) {
      // Avoids error when multiple calls on this method
      db = window.indexedDB.open(
          name,
          version: integerUtilities.max(1, integerUtilities.maxFromList(changes.keys)),
          onUpgradeNeeded: (idb.VersionChangeEvent event) {
            var db = (event.target as idb.Request).result;
            changes.keys.forEach((version) {
              if (version > event.oldVersion) {
                changes[version].forEach((callback) => callback(event));
              }
            });
          });
    }
    return db.then((_) => null); // Avoids to return the internal _db.
  }

  @override
  ITableStorage operator [](String name) {
    if (db == null) {
      throw 'An access to IndexedDB was made before opening it. Operation aborted';
    } else {
      if (!tableStorageMap.containsKey(name)) {
        tableStorageMap[name] = new DatabaseTableStorage(name, db, this);
      }
      return tableStorageMap[name];
    }
  }
}