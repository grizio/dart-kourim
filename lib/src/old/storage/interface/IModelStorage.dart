part of kourim.storage.interface;

/// This interface describes classes which possess a set of [ITableStorage] used to save data on local storage.
abstract class IModelStorage {
  /// Returns the [ITableStorage] in terms of given [name].
  ITableStorage operator [](String name);
}