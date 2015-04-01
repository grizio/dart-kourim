part of kourim.storage.lib;

/// This class is planned for the usage of [window.sessionStorage] and [window.localStorage].
@Injectable()
class MappedModelStorage implements IModelStorage {
  final Storage storage;
  Map<String, MappedTableStorage> tableStorageMap = {};

  final DatabaseApplicationName databaseApplicationName;

  MappedModelStorage(this.storage, this.databaseApplicationName);

  @override
  ITableStorage operator [](String name) {
    if (!tableStorageMap.containsKey(name)) {
      tableStorageMap[name] = new MappedTableStorage(storage, name, this);
    }
    return tableStorageMap[name];
  }
}