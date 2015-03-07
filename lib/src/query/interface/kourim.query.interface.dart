library kourim.query.interface;

import 'dart:async';

import 'package:klang/klang.dart';

import '../../core/lib/kourim.core.lib.dart';
import '../../storage/interface/kourim.storage.interface.dart' as storage;

part 'IEntityManager.dart';
part 'IQueryBuilder.dart';
part 'IQueryHelper.dart';
part 'IRequest.dart';

/// Defines a constraint of a query to apply for each model.
typedef bool Constraint(Object object);