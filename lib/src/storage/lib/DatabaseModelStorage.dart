part of kourim.storage.lib;

/// This class is planned for the usage of [IndexedDB].
@Injectable()
class DatabaseModelStorage implements IDatabase {
  Future<idb.Database> db;

  Map<String, DatabaseTableStorage> tableStorageMap = {};

  final DatabaseApplicationName databaseApplicationName;
  final DatabaseChangeManager databaseChangeManager;

  DatabaseModelStorage(this.databaseApplicationName, this.databaseChangeManager);

  @override
  Future open() {
    if (db == null) {
      // Avoids error when multiple calls on this method
      var changes = databaseChangeManager.changes;
      db = window.indexedDB.open(
          databaseApplicationName.name,
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
    return db.then((_) => null); // Avoids to return the internal db.
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