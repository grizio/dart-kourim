library kourim.storage.lib;

import 'dart:async';
import 'dart:html';
import 'dart:indexed_db' as idb;
import 'dart:convert';

import 'package:di/di.dart';

import 'package:klang/klang.dart';
import 'package:klang/utilities/integer.dart' as integerUtilities;

import '../interface/kourim.storage.interface.dart';

part 'DatabaseModelStorage.dart';
part 'DatabaseTableStorage.dart';
part 'MappedModelStorage.dart';
part 'MappedTableStorage.dart';

@Injectable()
class ApplicationDatabase extends DatabaseModelStorage {
  ApplicationDatabase(DatabaseApplicationName dan, DatabaseChangeManager dcm): super(dan, dcm);
}

@Injectable()
class InternalDatabase extends DatabaseModelStorage {
  InternalDatabase(@Internal() DatabaseApplicationName dan, @Internal() DatabaseChangeManager dcm): super(dan, dcm);
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
class InternalSessionStorage extends MappedModelStorage {
  InternalSessionStorage(@Internal() DatabaseApplicationName dan): super(window.sessionStorage, dan);
}

@Injectable()
class InternalLocalStorage extends MappedModelStorage {
  InternalLocalStorage(@Internal() DatabaseApplicationName dan): super(window.localStorage, dan);
}