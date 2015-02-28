library kourim.factory;

import 'package:kourim/config.dart' as config;
import 'internalConstants.dart' as internalConstants;
import 'core/kourim.core.lib.dart';
import 'query/kourim.query.lib.dart';
import 'storage/kourim.storage.lib.dart';

/// This library provides an implementation for each component of the system and permits the user to change the default implementation.
/// It is useful for having the system automatically handling the dependencies and providing a way to test each component.
/// This factory could be replaced by a dependency injection furthermore.

IModelDescription _modelDescription;

/// Changes the default `ModelDescription` used by the system.
/// This method should be used for testing only.
set modelDescription(IModelDescription modelDescription) {
  _modelDescription = modelDescription;
}

/// Gets the `ModelDescription`.
IModelDescription get modelDescription {
  if (_modelDescription == null) {
    // Default class
    _modelDescription = new ModelDescription();
  }
  return _modelDescription;
}

IMapper _mapper;

/// Changes the default `Mapper` used by the system.
/// This method should be used for testing only.
set mapper(IMapper mapper) {
  _mapper = mapper;
}

/// Gets the `Mapper`
IMapper get mapper {
  if (_mapper == null) {
    // Default class
    _mapper = new Mapper();
  }
  return _mapper;
}

IDatabase _database;

/// Changes the default `Database` stocking `IndexedDB` data of current application.
/// This method should be used for testing only.
set database(IDatabase database) {
  _database = database;
}

/// Gets the `Database` used to stock `IndexedDB` data of current application.
IDatabase get database {
  if (_database == null) {
    // Default class
    _database = new Database(config.databaseName);
  }
  return _database;
}

IDatabase _internalDatabase;

/// Changes the default `Database` used internally by `kourim`.
/// This method should be used for testing only.
set internalDatabase(IDatabase database) {
  _internalDatabase = database;
}

/// Gets the `Database` used internally by `kourim`.
IDatabase get internalDatabase {
  if (_internalDatabase == null) {
    // Default class
    _internalDatabase = new Database(internalConstants.database);
  }
  return _internalDatabase;
}

IQueryHelper _queryHelper;

/// Changes the default `QueryHelper`.
/// This method should be used for testing only.
set queryHelper(IQueryHelper queryHelper) {
  _queryHelper = queryHelper;
}

/// Gets the `QueryHelper`
IQueryHelper get queryHelper {
  if (_queryHelper == null) {
    // Default class
    _queryHelper = new QueryHelper();
  }
  return _queryHelper;
}

IEntityManager _entityManager;

set entityManager(IEntityManager entityManager) {
  _entityManager = entityManager;
}

IEntityManager get entityManager {
  if (_entityManager == null) {
    _entityManager = new EntityManager();
  }
  return _entityManager;
}