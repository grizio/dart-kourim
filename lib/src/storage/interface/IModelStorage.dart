part of kourim.storage.interface;

class local {
  const local();
}
class session {
  const session();
}
class indexedDb {
  const indexedDb();
}
class internal {
  const internal();
}

/// This interface describes classes which possess a set of [ITableStorage] used to save data on local storage.
abstract class IModelStorage {
  /// Returns the [ITableStorage] in terms of given [name].
  ITableStorage operator [](String name);
}