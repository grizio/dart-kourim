library kourim.storage.lib;

import 'dart:async';
import 'dart:html';
import 'dart:indexed_db' as idb;
import 'dart:convert';

import 'package:di/di.dart';

import 'package:klang/klang.dart';
import 'package:klang/utilities/integer.dart' as integerUtilities;
import 'package:klang/utilities/map.dart' as mapUtilities;

import '../interface/kourim.storage.interface.dart';

part 'DatabaseModelStorage.dart';
part 'DatabaseTableStorage.dart';
part 'MappedModelStorage.dart';
part 'MappedTableStorage.dart';

@Injectable()
class ApplicationDatabase extends DatabaseModelStorage {
  ApplicationDatabase(DatabaseApplicationName dan, DatabaseChangeManager dcm, @Internal() DatabaseChangeManager idcm): super(dan, dcm, idcm);
}

@Injectable()
class SessionStorage extends MappedModelStorage {
  SessionStorage(DatabaseApplicationName dan): super(window.sessionStorage, dan);
}

@Injectable()
class LocalStorage extends MappedModelStorage {
  LocalStorage(DatabaseApplicationName dan): super(window.localStorage, dan);
}

@Injectable()
class InternalDatabaseChangeManager extends DatabaseChangeManager {
  InternalDatabaseChangeManager() {
    onChange(1, (idb.VersionChangeEvent event){
      idb.Database db = (event.target as idb.Request).result;
      db.createObjectStore('__cacheForQueries');
      db.createObjectStore('__queries');
      db.createObjectStore('__cacheForTable');
    });
  }
}