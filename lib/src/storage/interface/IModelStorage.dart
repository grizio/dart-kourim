part of kourim.storage.interface;

class Local {
  const Local();
}
class Session {
  const Session();
}
class IndexedDb {
  const IndexedDb();
}
class Internal {
  const Internal();
}

/// This interface describes classes which possess a set of [ITableStorage] used to save data on local storage.
abstract class IModelStorage {
  /// Returns the [ITableStorage] in terms of given [name].
  ITableStorage operator [](String name);
}