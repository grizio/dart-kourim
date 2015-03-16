library kourim.factory;

import 'dart:html';

import 'package:kourim/config.dart' as config;
import 'internalConstants.dart' as internalConstants;
import 'core/interface/kourim.core.interface.dart';
import 'core/lib/kourim.core.lib.dart';
import 'query/interface/kourim.query.interface.dart';
import 'query/lib/kourim.query.lib.dart';
import 'storage/interface/kourim.storage.interface.dart';
import 'storage/lib/kourim.storage.lib.dart';

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
    _database = new DatabaseModelStorage(config.databaseName);
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
    _internalDatabase = new DatabaseModelStorage(internalConstants.database);
  }
  return _internalDatabase;
}


IModelStorage _sessionStorage;

/// Changes the default `sessionStorage`.
/// This method should be used for testing only.
set sessionStorage(IModelStorage sessionStorage) {
  _sessionStorage = sessionStorage;
}

/// Gets the `sessionStorage`
IModelStorage get sessionStorage {
  if (_sessionStorage == null) {
    _sessionStorage = new MappedModelStorage(window.sessionStorage);
  }
  return _sessionStorage;
}


IModelStorage _localStorage;

/// Changes the default `localStorage`.
/// This method should be used for testing only.
set localStorage(IModelStorage localStorage) {
  _localStorage = localStorage;
}

/// Gets the `localStorage`
IModelStorage get localStorage {
  if (_localStorage == null) {
    _localStorage = new MappedModelStorage(window.localStorage);
  }
  return _localStorage;
}


IEntityManager _entityManager;
/// Changes the default `EntityManager`
/// This method should be used for testing only.
set entityManager(IEntityManager entityManager) {
  _entityManager = entityManager;
}

/// Gets the `EntityManager`
IEntityManager get entityManager {
  if (_entityManager == null) {
    // Default class
    _entityManager = new EntityManager();
  }
  return _entityManager;
}


/// Method to create a request.
typedef IRequest IRequestCreation();

IRequestCreation _requestCreation;

/// Changes the function used to create requests.
/// This method should be used for testing only.
set requestCreation(IRequestCreation requestCreation) {
  _requestCreation = requestCreation;
}

/// Gets the function to create request.
IRequestCreation get requestCreation {
  if (_requestCreation == null) {
    _requestCreation = () => new Request();
  }
  return _requestCreation;
}

/// Creates a new request.
IRequest createRequest() {
  return requestCreation();
}


IModelValidation _modelValidation;

/// Gets the model validation.
IModelValidation get modelValidation {
  if (_modelValidation == null) {
    _modelValidation = new ModelValidation();
  }
  return _modelValidation;
}

/// Sets the model validation
/// This function should be called for tests only.
set modelValidation(IModelValidation modelValidation) {
  _modelValidation = modelValidation;
}


IConverterStore _converterStore;

/// Gets the converter store.
IConverterStore get converterStore {
  if (_converterStore == null) {
    _converterStore = new ConverterStore();
  }
  return _converterStore;
}

/// Sets the converter store
/// This function should be called for tests only.
set converterStore(IConverterStore converterStore) {
  _converterStore = converterStore;
}