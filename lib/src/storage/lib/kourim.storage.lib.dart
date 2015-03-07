library kourim.storage.lib;

import 'dart:async';
import 'dart:html';
import 'dart:indexed_db' as idb;
import 'dart:convert';

import 'package:klang/klang.dart';
import 'package:klang/utilities/integer.dart' as integerUtilities;

import 'package:kourim/config.dart' as config;
import '../../internalConstants.dart' as internalConstants;
import '../interface/kourim.storage.interface.dart';

part 'DatabaseModelStorage.dart';
part 'DatabaseTableStorage.dart';
part 'MappedModelStorage.dart';
part 'MappedTableStorage.dart';