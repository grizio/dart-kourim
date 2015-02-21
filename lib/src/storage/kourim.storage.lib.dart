library kourim.storage;

import 'dart:async';
import 'dart:html';
import 'dart:indexed_db' as idb;
import 'package:klang/klang.dart';
import 'package:klang/utilities/integer.dart' as integerUtilities;
import '../kourim.root.lib.dart';

part 'Database.dart';

Map<String, Database> _databases = {};
Database getDatabase(String name) {
  if (!_databases.containsKey(name)) {
    _databases[name] = new Database(name);
  }
  return _databases[name];
}

Database getAppDatabase() {
  return getDatabase(Config.databaseName);
}