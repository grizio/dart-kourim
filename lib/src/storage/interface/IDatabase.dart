part of kourim.storage.interface;

class DatabaseApplicationName {
  final String name;
  DatabaseApplicationName(this.name);
}

abstract class DatabaseChangeManager {
  Map<int, List<OnDatabaseChange>> changes = {};

  /// Before [open] is called, the developer can prepare database changes.
  /// This method adds a change in terms of given [version].
  ///
  ///     // On first version of the database, do "..." operations.
  ///     onChange(1, (event) => ...)
  ///
  /// See [dart.dom.indexed_db.IdbFactory#open] and JavaScript IndexedDB specifications for more information on database changes.
  void onChange(int version, OnDatabaseChange callback) {
    if (!changes.containsKey(version)) {
      changes[version] = [];
    }
    changes[version].add(callback);
  }
}

/// This interface describes classes which provide some database operations.
abstract class IDatabase extends IModelStorage {
  /// Opens the database.
  /// This will include the whole changes requested by [onChange].
  ///
  /// The considered version of the database will be the maximum version given in [onChange].
  Future open();
}