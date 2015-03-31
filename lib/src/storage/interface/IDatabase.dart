part of kourim.storage.interface;

@Injectable()
class DatabaseApplicationName {
  final String name;
  DatabaseApplicationName(this.name);
}

/// This interface describes classes which provide some database operations.
abstract class IDatabase extends IModelStorage {
  /// The name of the database.
  String get name;

  /// Before [open] is called, the developer can prepare database changes.
  /// This method adds a change in terms of given [version].
  ///
  ///     // On first version of the database, do "..." operations.
  ///     onChange(1, (event) => ...)
  ///
  /// See [dart.dom.indexed_db.IdbFactory#open] and JavaScript IndexedDB specifications for more information on database changes.
  void onChange(int version, OnDatabaseChange callback);

  /// Opens the database.
  /// This will include the whole changes requested by [onChange].
  ///
  /// The considered version of the database will be the maximum version given in [onChange].
  Future open();
}