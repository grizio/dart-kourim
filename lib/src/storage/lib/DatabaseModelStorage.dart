part of kourim.storage.lib;

/// This class is planned for the usage of [IndexedDB].
@Injectable()
class DatabaseModelStorage implements IDatabase {
  Future<idb.Database> _db;

  Map<String, DatabaseTableStorage> tableStorageMap = {};

  final DatabaseApplicationName databaseApplicationName;
  final DatabaseChangeManager databaseChangeManager;
  final DatabaseChangeManager internalDatabaseChangeManager;

  Future<idb.Database> get db {
    return open().then((_) => _db);
  }

  DatabaseModelStorage(this.databaseApplicationName, this.databaseChangeManager, @Internal() this.internalDatabaseChangeManager);

  @override
  Future open() {
    if (_db == null) {
      // Avoids error when multiple calls on this method
      var changes = databaseChangeManager.changes;
      var internalChanges = internalDatabaseChangeManager.changes;
      _db = window.indexedDB.open(
          databaseApplicationName.name,
          version: integerUtilities.max(1, integerUtilities.maxFromList(changes.keys)),
          onUpgradeNeeded: (idb.VersionChangeEvent event) {
            changes.keys.forEach((version) {
              if (version > event.oldVersion) {
                changes[version].forEach((callback) => callback(event));
              }
            });
            internalChanges.keys.forEach((version) {
              if (version > event.oldVersion) {
                internalChanges[version].forEach((callback) => callback(event));
              }
            });
          });
    }
    return _db.then((_) => null);
    // Avoids to return the internal db.
  }

  @override
  ITableStorage operator [](String name) {
    if (!tableStorageMap.containsKey(name)) {
      tableStorageMap[name] = new DatabaseTableStorage(name, db, this);
    }
    return tableStorageMap[name];
  }
}