library kourim.storage.interface;

import 'dart:async';
import 'dart:indexed_db' as idb;
import 'package:di/di.dart';
import 'package:klang/klang.dart';

part 'IDatabase.dart';
part 'IModelStorage.dart';
part 'ITableStorage.dart';

/// Function for handling database changes.
typedef void OnDatabaseChange(idb.VersionChangeEvent e);

/// Function for processing [values] without returning any result.
typedef void ForeachValues(Map<String, Object> values);

/// Function for processing [values] and returning a result from it.
typedef Object MapValues(Map<String, Object> values);

/// Function to check if the given [values] respect a specific constraint.
typedef bool Constraint(Map<String, Object> values);